data archive_file artifact {
  type        = "zip"
  source_dir  = "${path.module}/notify_slack"
  output_path = "${path.module}/notify_slack.zip"
}
