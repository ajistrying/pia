/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.slim',
    './app/components/**/*.html.slim',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}

