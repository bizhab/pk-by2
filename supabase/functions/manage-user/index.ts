import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ==========================================
// 1. TAMBAHKAN CORS HEADERS (WAJIB UNTUK FLUTTER)
// ==========================================
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  // ==========================================
  // 2. TANGANI REQUEST 'OPTIONS' (PREFLIGHT)
  // ==========================================
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Validasi hanya admin yang bisa akses
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { 
      status: 401, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }

  // Verifikasi token caller adalah admin
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )
  
  const { data: { user } } = await userClient.auth.getUser()
  if (!user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { 
      status: 401, headers: { ...corsHeaders } 
    })
  }

  const { data: profile } = await userClient
    .from('profiles').select('role').eq('id', user.id).single()
    
  if (profile?.role !== 'admin') {
    return new Response(JSON.stringify({ error: 'Forbidden: bukan admin' }), { 
      status: 403, headers: { ...corsHeaders } 
    })
  }

  const body = await req.json()
  const { action } = body

  try {
    // ── CREATE USER ──────────────────────────────────────
    if (action === 'create_user') {
      const { email, password, role, nama_lengkap, no_hp, gender,
              nim, angkatan, nip, bidang_studi, kode_pembina } = body

      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email, password, email_confirm: true
      })
      if (authError) throw authError

      const uid = authData.user.id

      await supabase.from('profiles').insert({
        id: uid, role, nama_lengkap, email, no_hp, gender
      })

      if (role === 'santri') {
        await supabase.from('santri').insert({ profile_id: uid, nim, angkatan })
      } else if (role === 'dosen') {
        await supabase.from('dosen').insert({ profile_id: uid, nip, bidang_studi })
      } else if (role === 'pembina') {
        await supabase.from('pembina').insert({ profile_id: uid, kode_pembina })
      }

      return new Response(JSON.stringify({ success: true, uid }), { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // ── DELETE USER ──────────────────────────────────────
    if (action === 'delete_user') {
      const { profile_id } = body
      const { error } = await supabase.auth.admin.deleteUser(profile_id)
      if (error) throw error
      
      return new Response(JSON.stringify({ success: true }), { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    return new Response(JSON.stringify({ error: 'Action tidak dikenal' }), { 
      status: 400, headers: { ...corsHeaders } 
    })

  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e)
    return new Response(JSON.stringify({ error: errorMessage }), { 
      status: 500, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})