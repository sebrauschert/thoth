# Calculate metrics
metrics <- predictions %>%
  metrics(truth = species, estimate = .pred_class)

# Create and save confusion matrix plot
predictions %>%
  conf_mat(truth = species, estimate = .pred_class) %>%
  autoplot() %>%
  ggplot2::ggsave(
    filename = "plots/confusion_matrix.png",
    plot = .,
    width = 8,
    height = 6
  ) 