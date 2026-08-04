import { defineConfig } from 'astro/config'
import mdx from '@astrojs/mdx'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  devToolbar: {
    enabled: false,
  },
  markdown: {
    shikiConfig: {
      themes: { light: 'min-light' },
      defaultColor: false,
    },
  },
  integrations: [mdx()],
  vite: {
    plugins: [tailwindcss()],
  },
})
