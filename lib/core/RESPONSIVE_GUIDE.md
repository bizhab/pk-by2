/// Responsive Layout Examples & Best Practices
/// 
/// Panduan menggunakan sistem responsive di aplikasi SIMAMAH

// ════════════════════════════════════════════════════════════════════════════
// 1. RESPONSIVE HELPERS & MediaQuery
// ════════════════════════════════════════════════════════════════════════════

/*
// Akses responsive info melalui extension
import 'package:pk_nanda/core/utils/responsive.dart';

// Dalam build():
@override
Widget build(BuildContext context) {
  // Check screen size
  if (context.isMobile) {
    return MobileLayout();
  } else if (context.isTablet) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
}

// Get specific responsive values
final padding = context.responsive.contentPadding;  // Adaptive padding
final width = context.responsive.width;              // Screen width
final colCount = context.responsive.getGridCount(    // Grid columns
  mobile: 1,
  tablet: 2,
  desktop: 3,
);
*/

// ════════════════════════════════════════════════════════════════════════════
// 2. RESPONSIVE GRID LAYOUT
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/responsive_widgets.dart';

// Responsive Grid otomatis mengubah jumlah kolom
ResponsiveGrid(
  mobileCount: 1,
  tabletCount: 2,
  desktopCount: 3,
  spacing: 16,
  children: [
    StatCard(...),
    StatCard(...),
    StatCard(...),
    StatCard(...),
  ],
)

// Atau gunakan ResponsiveWrap untuk layout yang lebih fleksibel
ResponsiveWrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3')),
  ],
)
*/

// ════════════════════════════════════════════════════════════════════════════
// 3. RESPONSIVE LAYOUT (Desktop vs Mobile)
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/responsive_widgets.dart';

// Tampilkan layout berbeda berdasarkan screen size
ResponsiveLayout(
  mobile: Column(children: [
    SearchBar(),
    SizedBox(height: 16),
    DataList(),
  ]),
  desktop: Row(children: [
    SizedBox(
      width: 300,
      child: SearchBar(),
    ),
    SizedBox(width: 16),
    Expanded(child: DataList()),
  ]),
)

// Atau pakai ResponsiveBuilder untuk full control
ResponsiveBuilder(
  builder: (context, responsive) {
    return Padding(
      padding: EdgeInsets.all(responsive.isMobile ? 12 : 24),
      child: Text('Responsive Padding'),
    );
  },
)
*/

// ════════════════════════════════════════════════════════════════════════════
// 4. ADAPTIVE DASHBOARD LAYOUT (dengan Sidebar/Drawer)
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/adaptive_layouts.dart';

// Desktop: Sidebar + Body | Mobile: Drawer + AppBar
@override
Widget build(BuildContext context) {
  return AdaptiveDashboardLayout(
    title: 'Admin Dashboard',
    sidebarBuilder: (context) => AdminSidebar(),
    body: Scaffold(
      appBar: AdaptiveAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ... content
            ],
          ),
        ),
      ),
    ),
  );
}
*/

// ════════════════════════════════════════════════════════════════════════════
// 5. RESPONSIVE TEXT
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/responsive_widgets.dart';

// Text size otomatis menyesuaikan screen size
ResponsiveText(
  'Welcome to SIMAMAH',
  mobileSize: 20,
  tabletSize: 24,
  desktopSize: 32,
  style: TextStyle(fontWeight: FontWeight.bold),
)

// Atau gunakan getFont dari responsive helper
final fontSize = context.responsive.getFont(
  mobile: 14,
  tablet: 16,
  desktop: 18,
);
*/

// ════════════════════════════════════════════════════════════════════════════
// 6. RESPONSIVE SPACING
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/responsive_widgets.dart';
import 'package:pk_nanda/core/theme/app_theme.dart';

// Spacing yang responsif
Column(
  children: [
    Text('Title'),
    ResponsiveSpace.vertical(
      mobile: 12,
      tablet: 16,
      desktop: 24,
    ),
    Text('Description'),
  ],
)

// Atau gunakan responsive padding
ResponsivePadding(
  mobile: EdgeInsets.all(12),
  tablet: EdgeInsets.all(16),
  desktop: EdgeInsets.all(24),
  child: Card(child: Text('Content')),
)

// Theme tokens untuk consistent spacing
Column(
  children: [
    Text('Title'),
    SizedBox(height: AppSpacing.md16),
    Text('Content'),
  ],
)
*/

// ════════════════════════════════════════════════════════════════════════════
// 7. RESPONSIVE CARDS & CONTAINERS
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/adaptive_layouts.dart';

// Container dengan responsive padding
ResponsiveContainer(
  padding: EdgeInsets.all(16),
  centered: true,  // Center pada desktop
  child: Column(
    children: [
      Text('Dashboard'),
      // ... content
    ],
  ),
)

// Section dengan title dan responsive padding
ResponsiveSection(
  title: 'Recent Data',
  actionText: 'View All',
  onAction: () {},
  child: DataTable(...),
)

// Responsive card grid
ResponsiveCardGrid(
  mobileCount: 1,
  tabletCount: 2,
  desktopCount: 3,
  children: [
    Card(child: ...),
    Card(child: ...),
    Card(child: ...),
  ],
)
*/

// ════════════════════════════════════════════════════════════════════════════
// 8. RESPONSIVE BUTTONS
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/widgets/adaptive_layouts.dart';

// Responsive button (expanded by default)
ResponsiveButton(
  label: 'Save',
  onPressed: () {},
  expanded: context.isMobile,  // Full width only on mobile
)

// Or combine with Form
Form(
  key: _formKey,
  child: Padding(
    padding: context.responsive.contentPadding,
    child: Column(
      children: [
        TextFormField(...),
        SizedBox(height: 16),
        ResponsiveButton(
          label: 'Login',
          onPressed: _login,
          expanded: true,
        ),
      ],
    ),
  ),
)
*/

// ════════════════════════════════════════════════════════════════════════════
// 9. BREAKPOINTS REFERENCE
// ════════════════════════════════════════════════════════════════════════════

/*
import 'package:pk_nanda/core/utils/responsive.dart';

ResponsiveBreakpoints:
  - mobile: < 600px
  - tablet: 600px - 1024px
  - desktop: >= 1024px
  
  - smallMobile: < 480px
  - largeDesktop: >= 1440px

Sidebar Widths:
  - Mobile: Hidden (0)
  - Tablet: 220px
  - Desktop: 280px
*/

// ════════════════════════════════════════════════════════════════════════════
// 10. BEST PRACTICES CHECKLIST
// ════════════════════════════════════════════════════════════════════════════

/*
✅ DO:
1. Use context.responsive untuk MediaQuery checks
2. Gunakan ResponsiveGrid/ResponsiveWrap untuk layouts fleksibel
3. Manfaatkan AppSpacing constants untuk padding yang konsisten
4. Test di mobile (360px), tablet (768px), desktop (1440px)
5. Gunakan ResponsiveLayout untuk layout yang berbeda per breakpoint
6. Use ResponsiveBuilder untuk custom responsive logic
7. Always provide mobile endpoint sebelum tablet/desktop

❌ DON'T:
1. Jangan hardcode padding values - gunakan AppSpacing
2. Jangan gunakan fixed width/height untuk container utama
3. Jangan lupa test orientasi landscape pada mobile
4. Jangan nesting ResponsiveBuilder terlalu dalam
5. Jangan gunakan MediaQuery.of() langsung - gunakan extension
6. Jangan membuat sidebar yang tidak collapsible di mobile
7. Jangan lupakan keyboard height pada mobile (viewInsets)
*/

// ════════════════════════════════════════════════════════════════════════════
// 11. QUICK REFERENCE - RESPONSIVE CHECKS
// ════════════════════════════════════════════════════════════════════════════

/*
// Check screen size
context.isMobile      // < 600px
context.isTablet      // 600px - 1024px
context.isDesktop     // >= 1024px
context.isPortrait    // Portrait orientation
context.isLandscape   // Landscape orientation

// Get dimensions
context.width         // Screen width
context.height        // Screen height
context.responsive.padding          // Status bar padding
context.responsive.isKeyboardVisible // Keyboard visible

// Get responsive values
context.responsive.contentPadding   // Mobile: 12, Tablet: 16, Desktop: 24
context.responsive.sidebarWidth    // Mobile: 0, Tablet: 220, Desktop: 280
context.responsive.maxContentWidth  // Desktop: 1200, Tablet: 800
*/

// ════════════════════════════════════════════════════════════════════════════
// SUMMARY: Responsive System Component Architecture
// ════════════════════════════════════════════════════════════════════════════

/*
📁 lib/core/

├── 📁 utils/
│   └── responsive.dart
│       ├── ResponsiveBreakpoints       (Breakpoint constants)
│       ├── ResponsiveHelper            (MediaQuery wrapper)
│       └── ResponsiveContext Extension (Easy context.responsive access)
│
├── 📁 widgets/
│   ├── responsive_widgets.dart
│   │   ├── ResponsiveGrid              (Auto-column grid)
│   │   ├── ResponsiveWrap              (Flexible wrap)
│   │   ├── ResponsiveLayout            (Layout switcher)
│   │   ├── ResponsiveBuilder           (Custom responsive)
│   │   ├── ResponsiveSpace             (Responsive SizedBox)
│   │   ├── ResponsivePadding           (Responsive padding)
│   │   ├── ResponsiveText              (Adaptive font size)
│   │   └── ResponsiveSliverGrid        (Sliver grid)
│   │
│   └── adaptive_layouts.dart
│       ├── AdaptiveDashboardLayout     (Sidebar/Drawer switcher)
│       ├── AdaptiveAppBar              (Responsive app bar)
│       ├── ResponsiveContainer         (Max-width container)
│       ├── ResponsiveSection           (Title + content)
│       ├── ResponsiveCardGrid          (Card grid layout)
│       ├── ResponsiveButton            (Adaptive button)
│       ├── ResponsiveDialog            (Responsive dialog)
│       ├── ResponsiveListTile          (List/card tile)
│       └── ResponsiveSectionDivider    (Section divider)
│
└── 📁 theme/
    └── app_theme.dart
        ├── AppColors                   (Colors)
        ├── AppTextStyles               (Typography)
        └── AppSpacing                  (Spacing tokens)
*/
