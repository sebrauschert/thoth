# Generate example analytics project data
set.seed(42)

example_projects <- data.frame(
  project_id = paste0("PRJ", sprintf("%03d", 1:100)),
  start_date = as.Date("2023-01-01") + sample(0:365, 100, replace = TRUE),
  team_size = sample(2:10, 100, replace = TRUE),
  uses_dvc = sample(c(TRUE, FALSE), 100, replace = TRUE, prob = c(0.7, 0.3)),
  uses_docker = sample(c(TRUE, FALSE), 100, replace = TRUE, prob = c(0.6, 0.4)),
  completion_rate = round(runif(100, min = 60, max = 100), 1)
)

# Save the data
usethis::use_data(example_projects, overwrite = TRUE) 