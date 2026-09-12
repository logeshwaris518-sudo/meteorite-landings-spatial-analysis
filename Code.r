# ============================================================
# Meteorite Landings - Interactive Shiny Dashboard
# ============================================================

library(shiny)
library(dplyr)
library(tidyr)
library(sf)
library(leaflet)
library(spatstat)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)

# ---- Load and prepare data ----
meteorites <- read.csv("C:/Users/Logeshwari/Pictures/Logeshwari/Projects/R_Projects/Meteorite_Landings/Meteorite_Landings.csv", stringsAsFactors = FALSE)
meteorites$reclat[meteorites$reclat == 0 & meteorites$reclong == 0] <- NA
meteorites$reclong[is.na(meteorites$reclat)] <- NA

meteorites_clean <- meteorites %>%
  filter(!is.na(reclat), !is.na(reclong), !is.na(mass..g.)) %>%
  filter(reclat >= -90, reclat <= 90, reclong >= -180, reclong <= 180) %>%
  mutate(year = as.numeric(substr(year, 1, 4))) %>%
  filter(!is.na(year), year >= 860, year <= 2016)

world <- ne_countries(scale = "medium", returnclass = "sf")
meteor_sf <- st_as_sf(meteorites_clean, coords = c("reclong", "reclat"), crs = 4326)
meteor_with_continent <- st_join(meteor_sf, world["continent"])

# ---- UI ----
ui <- fluidPage(
  titlePanel("Meteorite Landings — Spatial Analysis Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("continent", "Select Continent:",
                  choices = c("All", sort(unique(na.omit(meteor_with_continent$continent)))),
                  selected = "All"),
      
      sliderInput("yearRange", "Year Range:",
                  min = min(meteor_with_continent$year, na.rm = TRUE),
                  max = max(meteor_with_continent$year, na.rm = TRUE),
                  value = c(1900, 2016), sep = ""),
      
      checkboxGroupInput("fallType", "Discovery Type:",
                         choices = c("Fell", "Found"),
                         selected = c("Fell", "Found"))
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Interactive Map", leafletOutput("map", height = 500)),
        tabPanel("Bias Ratio by Continent", plotOutput("biasPlot", height = 500)),
        tabPanel("Kernel Density", plotOutput("densityPlot", height = 500))
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  
  filtered_data <- reactive({
    data <- meteor_with_continent %>%
      st_drop_geometry() %>%
      filter(year >= input$yearRange[1], year <= input$yearRange[2],
             fall %in% input$fallType)
    
    if (input$continent != "All") {
      data <- data %>% filter(continent == input$continent)
    }
    
    coords <- st_coordinates(meteor_with_continent)
    data$reclong <- coords[match(rownames(data), rownames(st_drop_geometry(meteor_with_continent))), 1]
    data$reclat  <- coords[match(rownames(data), rownames(st_drop_geometry(meteor_with_continent))), 2]
    
    data
  })
  
  output$map <- renderLeaflet({
    data <- filtered_data()
    
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~reclong, lat = ~reclat,
        radius = ~log(mass..g. + 1) / 2,
        color = ~ifelse(fall == "Fell", "red", "blue"),
        stroke = FALSE, fillOpacity = 0.5,
        popup = ~paste0("<b>", name, "</b><br>Class: ", recclass,
                        "<br>Mass: ", mass..g., "g<br>Year: ", year)
      ) %>%
      addLegend("bottomright", colors = c("red", "blue"),
                labels = c("Fell (observed)", "Found (discovered)"),
                title = "Discovery Type")
  })
  
  output$biasPlot <- renderPlot({
    bias_data <- meteor_with_continent %>%
      st_drop_geometry() %>%
      filter(year >= input$yearRange[1], year <= input$yearRange[2]) %>%
      group_by(continent, fall) %>%
      summarise(count = n(), .groups = "drop") %>%
      pivot_wider(names_from = fall, values_from = count, values_fill = 0) %>%
      mutate(found_ratio = Found / (Fell + Found))
    
    ggplot(bias_data, aes(x = reorder(continent, found_ratio), y = found_ratio, fill = continent)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      labs(title = "Discovery Bias by Continent",
           x = "Continent", y = "Found Ratio (higher = stronger discovery bias)") +
      theme_minimal()
  })
  
  output$densityPlot <- renderPlot({
    data <- filtered_data()
    
    if (nrow(data) < 5) {
      plot.new()
      text(0.5, 0.5, "Not enough points for this selection")
      return()
    }
    
    window <- owin(xrange = range(data$reclong, na.rm = TRUE),
                   yrange = range(data$reclat, na.rm = TRUE))
    pp <- ppp(data$reclong, data$reclat, window = window)
    
    density_map <- density(pp, sigma = bw.diggle(pp))
    plot(density_map, main = paste("Kernel Density -", input$continent))
  })
}

# ---- Run the app ----
shinyApp(ui = ui, server = server)