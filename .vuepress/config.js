module.exports = {
  title: 'Roblox Lua Promise',
  description: 'Promise implementation for Roblox',

  base: '/roblox-lua-promise/',

  plugins: [
    ['vuepress-plugin-api-docs-generator', {
      defaults: {
        returns: ['void'],
        property_tags: [{
          name: 'read only',
          unless: ['writable']
        }]
      },
      types: {
        void: {
          summary: 'Interchangeable for nil in most cases.'
        },
      },
      tagColors: {
        'read only': '#1abc9c',
        'writable': '#3498db',
        'deprecated': '#e7c000',
        'client only': '#349AD5',
        'server only': '#01CC67',
        'enums': '#e67e22'
      },
      methodCallOperator: ':',
      staticMethodCallOperator: '.'
    }]
  ],

  themeConfig: {
    activeHeaderLinks: false,
    searchPlaceholder: 'Press S to search...',
    nav: [
      { text: 'API Reference', link: '/lib/' },
      { text: 'GitHub', link: 'https://github.com/evaera/roblox-lua-promise' }
    ],

    sidebarDepth: 3,
    sidebar: [
      '/lib/Installation',
      '/lib/WhyUsePromises',
      '/lib/Tour',
      '/lib/Examples',
      '/CHANGELOG',
      '/lib/'
    ]
  }
}