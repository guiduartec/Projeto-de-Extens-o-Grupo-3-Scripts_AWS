resource "aws_glue_catalog_database" "venuste_db" {
  name        = "venuste_db"
  description = "Database for weather temperature analysis"
}

resource "aws_glue_catalog_table" "weather_data_from_stations" {
  name          = "weather_data_from_stations"
  database_name = aws_glue_catalog_database.venuste_db.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Weather temperature data from stations"

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/weather/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "weather_data_from_stations"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"            = ";"
        "serialization.format"   = ","
        "line.delim"            = "\n"
      }
    }

    columns {
      name = "estacao"
      type = "string"
    }

    columns {
      name = "mes"
      type = "int"
    }

    columns {
      name = "nome_mes"
      type = "string"
    }

    columns {
      name = "temperatura_media"
      type = "double"
    }
  }

  parameters = {
    EXTERNAL              = "TRUE"
    "classification"      = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}