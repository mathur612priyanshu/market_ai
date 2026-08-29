/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          primary: '#0a0d16',
          secondary: '#111524',
          tertiary: '#192035',
        },
        accent: {
          purple: '#9d4edd',
          indigo: '#5390d9',
          cyan: '#4cc9f0',
          pink: '#f72585',
          green: '#06d6a0',
          orange: '#ff9f1c',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        display: ['Outfit', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
