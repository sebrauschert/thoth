#' Create Custom Quarto Template
#'
#' Creates a custom Quarto template with specified branding options
#'
#' @param template_name Character. Name of the template
#' @param logo_path Character. Path to logo file (optional)
#' @param primary_color Character. Primary brand color in hex format (optional)
#' @param secondary_color Character. Secondary brand color in hex format (optional)
#' @param font_family Character. Main font family to use (optional)
#' @param output_dir Character. Directory to save the template (optional)
#'
#' @return Invisibly returns the path to the created template
#' @export
#'
#' @examples
#' \dontrun{
#' create_quarto_template(
#'   template_name = "company_template",
#'   logo_path = "path/to/logo.png",
#'   primary_color = "#FF0000"
#' )
#' }
create_quarto_template <- function(template_name,
                                 logo_path = NULL,
                                 primary_color = NULL,
                                 secondary_color = NULL,
                                 font_family = NULL,
                                 output_dir = "reports/templates") {
  
  # Create template directory
  template_dir <- file.path(output_dir, template_name)
  dir.create(template_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Create custom CSS
  css_content <- create_custom_css(
    primary_color = primary_color,
    secondary_color = secondary_color,
    font_family = font_family
  )
  writeLines(css_content, file.path(template_dir, "custom.css"))
  
  # Copy logo if provided
  if (!is.null(logo_path) && file.exists(logo_path)) {
    file.copy(logo_path, file.path(template_dir, basename(logo_path)))
  }
  
  # Create template YAML
  yaml_content <- create_template_yaml(
    template_name = template_name,
    logo_path = if (!is.null(logo_path)) basename(logo_path) else NULL
  )
  writeLines(yaml_content, file.path(template_dir, "_template.yml"))
  
  # Success message
  cli::cli_alert_success("Quarto template created at {.path {template_dir}}")
  
  invisible(template_dir)
}

#' Create Custom CSS for Quarto Template
#' @keywords internal
create_custom_css <- function(primary_color = NULL,
                            secondary_color = NULL,
                            font_family = NULL) {
  css_lines <- c("/* Custom styles for Quarto template */")
  
  if (!is.null(primary_color)) {
    css_lines <- c(css_lines, "", 
                  sprintf(":root { --primary-color: %s; }", primary_color),
                  "
.navbar {
  background-color: var(--primary-color);
}

.title {
  color: var(--primary-color);
}")
  }
  
  if (!is.null(secondary_color)) {
    css_lines <- c(css_lines, "",
                  sprintf(":root { --secondary-color: %s; }", secondary_color),
                  "
a {
  color: var(--secondary-color);
}

.nav-link:hover {
  color: var(--secondary-color);
}")
  }
  
  if (!is.null(font_family)) {
    css_lines <- c(css_lines, "",
                  sprintf("body { font-family: %s; }", font_family))
  }
  
  paste(css_lines, collapse = "\n")
}

#' Create Template YAML Configuration
#' @keywords internal
create_template_yaml <- function(template_name, logo_path = NULL) {
  yaml_lines <- c(
    "format:",
    "  html:",
    "    theme: cosmo",
    "    css: custom.css",
    "    toc: true",
    "    code-fold: true",
    "    code-tools: true",
    "    df-print: paged",
    "    fig-width: 8",
    "    fig-height: 6",
    "    fig-format: png",
    "    fig-dpi: 300"
  )
  
  if (!is.null(logo_path)) {
    yaml_lines <- c(yaml_lines,
                   "    logo: logo.png")
  }
  
  paste(yaml_lines, collapse = "\n")
}

#' Apply Template to Report
#'
#' Applies a custom template to a Quarto report
#'
#' @param report_path Character. Path to the Quarto report
#' @param template_name Character. Name of the template to apply
#'
#' @return Invisibly returns TRUE on success
#' @export
#'
#' @examples
#' \dontrun{
#' apply_template_to_report("reports/analysis.qmd", "company_template")
#' }
apply_template_to_report <- function(report_path, template_name) {
  # Read the report content
  report_content <- readLines(report_path)
  
  # Find YAML front matter
  yaml_start <- which(report_content == "---")[1]
  yaml_end <- which(report_content == "---")[2]
  
  if (length(yaml_start) == 0 || length(yaml_end) == 0) {
    cli::cli_abort("No valid YAML front matter found in the report")
  }
  
  # Read template YAML
  template_yaml <- readLines(file.path("reports/templates", template_name, "_template.yml"))
  
  # Merge YAML sections
  new_content <- c(
    report_content[1:yaml_start],
    template_yaml,
    report_content[yaml_end:length(report_content)]
  )
  
  # Write back to file
  writeLines(new_content, report_path)
  
  cli::cli_alert_success("Template {.val {template_name}} applied to {.path {report_path}}")
  
  invisible(TRUE)
} 