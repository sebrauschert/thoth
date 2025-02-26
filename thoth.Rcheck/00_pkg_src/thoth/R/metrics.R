#' Calculate model performance metrics
#'
#' @param data A data frame containing the columns specified in `truth` and `estimate`.
#' @param truth The column name containing the true values.
#' @param estimate The column name containing the predicted values.
#' @param event_level A character string indicating which level of the outcome is considered the "event".
#' @param ... Additional arguments passed to yardstick::metrics.
#'
#' @return A tibble with model performance metrics.
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#' data(mtcars)
#' # Create a binary outcome
#' mtcars <- mtcars %>% 
#'   mutate(vs_factor = factor(vs))
#' # Fit a model
#' model <- glm(vs ~ mpg + cyl, data = mtcars, family = "binomial")
#' # Make predictions
#' preds <- predict(model, type = "response")
#' # Create prediction data frame
#' pred_data <- mtcars %>%
#'   mutate(pred = factor(ifelse(preds > 0.5, 1, 0)))
#' # Calculate metrics
#' metrics(pred_data, truth = vs_factor, estimate = pred)
#' }
#' @importFrom yardstick metrics
metrics <- function(data, truth, estimate, event_level = NULL, ...) {
  yardstick::metrics(data = data, truth = truth, estimate = estimate, 
                    event_level = event_level, ...)
}

#' Create a confusion matrix
#'
#' @param data A data frame containing the columns specified in `truth` and `estimate`.
#' @param truth The column name containing the true values.
#' @param estimate The column name containing the predicted values.
#' @param ... Additional arguments passed to yardstick::conf_mat.
#'
#' @return A confusion matrix.
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#' data(mtcars)
#' # Create a binary outcome
#' mtcars <- mtcars %>% 
#'   mutate(vs_factor = factor(vs))
#' # Fit a model
#' model <- glm(vs ~ mpg + cyl, data = mtcars, family = "binomial")
#' # Make predictions
#' preds <- predict(model, type = "response")
#' # Create prediction data frame
#' pred_data <- mtcars %>%
#'   mutate(pred = factor(ifelse(preds > 0.5, 1, 0)))
#' # Calculate confusion matrix
#' conf_mat(pred_data, truth = vs_factor, estimate = pred)
#' }
#' @importFrom yardstick conf_mat
conf_mat <- function(data, truth, estimate, ...) {
  yardstick::conf_mat(data = data, truth = truth, estimate = estimate, ...)
} 