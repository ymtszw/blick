module.exports = {
  'env': {
    'node': true,
    'mocha': true,
  },
  'parserOptions': {
    'sourceType': 'module',
    'ecmaVersion': 2017
  },
  'extends': 'eslint:recommended',
  'rules': {
    'indent': [
      'error',
      2
    ],
    'linebreak-style': [
      'error',
      'unix'
    ],
    'quotes': [
      'error',
      'single'
    ],
    'semi': [
      'error',
      'never'
    ],
    'no-console': [
      'off',
    ],
    'prefer-arrow-callback': [
      'error',
    ]
  }
}
