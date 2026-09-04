task :deploy do
  sh 'git push origin main'
  sh "rsync -auP --no-p --exclude-from='rsync-exclude.txt' . $VISKAMA_REMOTE"
end

task :sync do
  sh "rsync -auP --no-p --exclude-from='rsync-exclude.txt' . $VISKAMA_REMOTE"
end

task default: [:deploy]
