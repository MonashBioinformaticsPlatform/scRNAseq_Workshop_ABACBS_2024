
library(stringr)
library(yaml)

get_script <- function(filename) {
    lines <- readLines(filename, warn=FALSE)
    lines <- str_trim(lines, "right")

    state <- "main"
    blank <- ""
    need_blank <- FALSE
    comment_code <- FALSE
    output <- c()
    show <- function(...) output[length(output)+1] <<- paste0(...)
    for(line in lines) {
        if (state == "main" && line == "---") {
            state <- "start"
        } else if (state == "start" && str_detect(line,"^---")) {
            state <- "main"
            need_blank <- FALSE
        } else if (state == "main" && str_detect(line,"<!--omit-begin-->")) {
            state <- "omit"
        } else if (state == "omit" && str_detect(line,"<!--omit-end-->")) {
            state <- "main"
        } else if (state == "main" && str_detect(line,"^```.*include=FALSE")) {
            state <- "hidden_code"
        } else if (state == "main" && str_detect(line,"^```")) {
            state <- "code"
            comment_code <- !str_detect(line,"^``` *\\{ *[rR]")
            show("")
        } else if (state %in% c("code","hidden_code") && str_detect(line,"^```")) {
            state <- "main"
            need_blank <- TRUE
            blank <- ""
        } else if (state == "main") {
            clean_line <- str_replace_all(line,"`|<details>|</details>|<summary>|</summary>|\\{\\..*\\}","")
            clean_line <- str_trim(clean_line, "right")
            if (clean_line=="" || clean_line=="\\" || clean_line=="***") {
                need_blank <- TRUE
            } else if (str_detect(clean_line,"^<!--.*-->$")) {
                # Comment.
            } else if (str_detect(clean_line,"^#+")) {
                # Heading
                clean_line <- str_replace_all(clean_line,"\\{.*\\}", "")
                clean_line <- str_trim(clean_line, "right")
                depth <- nchar(str_match(clean_line, "^#*")[1,1])
                if (depth == 1) clean_line <- paste0(clean_line, " ================")
                if (depth == 2) clean_line <- paste0(clean_line, " --------")
                if (depth <= 2) {
                    show("")
                    show("")
                } else {
                    show(blank)
                }
                show(clean_line)
                need_blank <- TRUE
                blank <- "#"
            } else {
                if (need_blank)
                    show(blank)
                
                indent <- nchar(str_match(clean_line, "^ *")[1,1])
                exdent <- nchar(str_match(clean_line, "^[^A-Za-z0-9]*")[1,1])
                wrap <- str_wrap(clean_line, indent=indent, exdent=exdent, width=80) |> str_split_1("\n")
                for(item in wrap) show("# ", item)
                need_blank <- FALSE
                blank <- "#"
            }
        } else if (state == "code") {
            if (comment_code) line <- paste0("# ",line)
            show(line)
        }
    }
    
    output
}


#filenames <- list.files(pattern="[0-9].*\\.Rmd") |> sort() |>
#    setdiff(c("01-01-setup.Rmd", "07-Acknowledgements.Rmd", "08-session_info.Rmd"))

filenames <- read_yaml("_bookdown.yml", readLines.warn=FALSE)$rmd_files |>
    setdiff(c(
        "index.Rmd", 
        "02-schedual.Rmd", 
        "01-01-setup.Rmd", 
        "05-01-resources.Rmd",
        "07-Acknowledgements.Rmd",
        "07-01-seuratobject.Rmd",
        "08-session_info.Rmd"))

output <- lapply(filenames, get_script) |> unlist()

writeLines(output, "docs/workshop.R")

# source("scripts/make_R_script.R")