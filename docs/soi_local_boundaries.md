# Official local map boundaries

`soi_pollachi_villages.geojson` contains exactly five village administrative polygons: Kottur (TP), Thensangampalayam, Pethanaickanur, Muthalamada-I and Muthalamada-II. Their identifiers and categories come from Survey of India village boundary datasets and their Local Government Directory village codes. Coordinates were transformed from the source LCC_WGS84 projection into RFC 7946 WGS84 longitude/latitude. Original multipart geometry is retained.

## Source and limits

- Survey of India village boundary database: https://surveyofindia.gov.in/pages/village-boundary-data-base-of-entire-india
- Survey of India digital product portal (Tamil Nadu and Kerala downloads): https://onlinemaps.surveyofindia.gov.in/Digital_Product_Show.aspx/Home.aspx
- The downloaded source metadata records ORGI data received in 2023 and metadata created 2025-08-20.
- These are village administrative polygons. They do not represent individual residences, surveyed property lots, forest reserve limits, restricted zones, or the Tamil Nadu–Kerala state boundary line.
- Map display only. The geofence service explicitly excludes `village` polygons from hazard calculations.
- Source ZIPs and temporary conversion libraries are not bundled in the app. Original illustrative project assets were kept unchanged.

Download links: https://surveyofindia.gov.in/documents/TAMILNADU.zip and https://surveyofindia.gov.in/documents/KERALA.zip
