task :watch_inline_rbs do
  sh 'fswatch -0 . | xargs -0 -n1 bundle exec rbs-inline --output'
end

task :rubocop_lsp do
  sh 'bundle exec rubocop --lsp'
end
