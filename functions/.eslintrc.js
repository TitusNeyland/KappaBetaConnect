module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  rules: {
    'indent': ['error', 4],
    'max-len': ['error', { 'code': 120 }],
    'quotes': ['error', 'single'],
  },
}; 