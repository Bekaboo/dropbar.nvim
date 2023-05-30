globals = { 'vim' }
max_line_length = false

files['tests'] = {
  unused = false,
  globals = {
    'test',
    'after_each',
    'assert',
    'before_each',
    'clear',
    'describe',
    'it',
    'pending',
  },
}
