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
      name = "data"
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

resource "aws_glue_catalog_table" "comentarios_clientes" {
  name          = "comentarios_clientes"
  database_name = aws_glue_catalog_database.venuste_db.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Tabela de comentários de clientes sobre roupas"

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/comentarios/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "comentarios_clientes"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"            = ";"
        "serialization.format"   = ","
        "line.delim"             = "\n"
      }
    }

    columns {
      name = "comment_username"
      type = "string"
    }

    columns {
      name = "comment_text"
      type = "string"
    }

    columns {
      name = "comment_created_at"
      type = "string" 
    }

    columns {
      name = "comment_id"
      type = "int"
    }

    columns {
      name = "comment_user_id"
      type = "int"
    }
  }

  parameters = {
    EXTERNAL                  = "TRUE"
    "classification"          = "csv"
    "typeOfData"              = "file"
    "compressionType"         = "none"
    "skip.header.line.count"  = "1"
  }
}

resource "aws_glue_catalog_table" "alerta" {
  name          = "alerta"
  database_name = aws_glue_catalog_database.venuste_db.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Tabela de alertas"

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/alerta/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "alerta"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "id_alerta"
      type = "int"
    }

    columns {
      name = "fk_item_estoque"
      type = "int"
    }

    columns {
      name = "descricao"
      type = "string"
    }

    columns {
      name = "data_hora"
      type = "string" # se o CSV tiver formato estranho, podemos deixar como string
    }
  }

  parameters = {
    EXTERNAL                  = "TRUE"
    "classification"          = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count"  = "1"
  }
}

resource "aws_glue_catalog_table" "autocomplete_saida" {
  name          = "autocomplete_saida"
  database_name = aws_glue_catalog_database.venuste_db.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Tabela de saída com autocomplete"

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/autocomplete_saida/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "autocomplete_saida"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "fk_lote"
      type = "int"
    }

    columns {
      name = "fk_item_estoque"
      type = "int"
    }

    columns {
      name = "descricao"
      type = "string"
    }

    columns {
      name = "quantidade"
      type = "int"
    }

    columns {
      name = "preco"
      type = "double" # se estiver com vírgula (ex: 12,50), pode precisar ser string
    }

    columns {
      name = "id_lote_item_estoque"
      type = "int"
    }

    columns {
      name = "fk_categoria_pai"
      type = "int"
    }
  }

  parameters = {
    EXTERNAL                  = "TRUE"
    "classification"          = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count"  = "1"
  }
}

resource "aws_glue_catalog_table" "caracteristica_item_estoque" {
  name          = "caracteristica_item_estoque"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/caracteristica_item_estoque/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "caracteristica_item_estoque"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "fk_categoria"
      type = "int"
    }
    columns {
      name = "fk_item_estoque"
      type = "int"
    }
  }

  parameters = {
    EXTERNAL                 = "TRUE"
    "classification"         = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "categoria" {
  name          = "categoria"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/categoria/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "categoria"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "id_categoria"
      type = "int"
    }
    columns {
      name = "nome"
      type = "string"
    }
    columns {
      name = "fk_categoria_pai"
      type = "int"
    }
  }

  parameters = {
    EXTERNAL                 = "TRUE"
    "classification"         = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "confeccao_roupa" {
  name          = "confeccao_roupa"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/confeccao_roupa/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "confeccao_roupa"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "id_confeccao_roupa"
      type = "int"
    }
    columns {
      name = "fk_roupa"
      type = "int"
    }
    columns {
      name = "fk_tecido"
      type = "int"
    }
    columns {
      name = "qtd_tecido"
      type = "double"
    }
  }

  parameters = {
    EXTERNAL                 = "TRUE"
    "classification"         = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "controle_acesso" {
  name          = "controle_acesso"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/controle_acesso/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "controle_acesso"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "fk_funcionario"
       type = "int" 
       }
    columns { 
      name = "fk_permissao"
         type = "int" 
         }
  }

  parameters = { EXTERNAL = "TRUE", "classification" = "csv", "skip.header.line.count" = "1" }
}

resource "aws_glue_catalog_table" "funcionario" {
  name          = "funcionario"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/funcionario/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "funcionario"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ";"
        "serialization.format" = ";"
      }
    }

    columns {
      name = "id_funcionario"
      type = "int"
    }
    columns {
      name = "nome"
      type = "string"
    }
    columns {
      name = "cpf"
      type = "string"
    }
    columns {
      name = "telefone"
      type = "string"
    }
    columns {
      name = "email"
      type = "string"
    }
    columns {
      name = "senha"
      type = "string"
    }
  }

  parameters = {
    EXTERNAL                 = "TRUE"
    "classification"         = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "imagem" {
  name          = "imagem"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/imagem/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "imagem"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_imagem" 
      type = "int" 
      }
    columns { 
      name = "url"
      type = "string" 
      }
  }

  parameters = { EXTERNAL = "TRUE", "classification" = "csv", "skip.header.line.count" = "1" }
}

resource "aws_glue_catalog_table" "item_estoque" {
  name          = "item_estoque"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/item_estoque/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "item_estoque"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_item_estoque" 
      type = "int"
      }
    columns { 
      name = "fk_categoria"
      type = "int" 
      }
    columns { 
      name = "fk_prateleira"   
      type = "int" 
      }
    columns { 
      name = "fk_imagem"       
      type = "int" 
      }
    columns { 
      name = "descricao"       
      type = "string" 
      }
    columns { 
      name = "notificar"       
      type = "int" 
      }
    columns { 
      name = "complemento"     
      type = "string" 
      }
    columns { 
      name = "peso"            
      type = "double" 
      }
    columns { 
      name = "qtd_minimo"      
      type = "int" 
      }
    columns { 
      name = "qtd_armazenado"  
      type = "int" 
      }
    columns { 
      name = "preco"           
      type = "double" 
      }
  }

  parameters = { EXTERNAL = "TRUE", 
  "classification" = "csv",
  "typeOfData"         = "file"
    "compressionType"    = "none" 
  "skip.header.line.count" = "1" }
}

resource "aws_glue_catalog_table" "lote_item_estoque" {
  name          = "lote_item_estoque"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/lote_item_estoque/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "lote_item_estoque"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_lote_item_estoque" 
      type = "int" 
      }
    columns { 
      name = "fk_item_estoque"      
      type = "int" 
      }
    columns { 
      name = "fk_lote"              
      type = "int" 
      }
    columns { 
      name = "qtd_item"             
      type = "double" 
      }
    columns { 
      name = "preco"                
      type = "double" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "lote" {
  name          = "lote"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/lote/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "lote"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_lote"       
      type = "int" 
      }
    columns { 
      name = "descricao"     
      type = "string" 
      }
    columns { 
      name = "dt_entrada"    
      type = "string" 
      } # pode virar date se quiser
    columns { 
      name = "fk_parceiro"   
      type = "int" 
      }
    columns { 
      name = "fk_responsavel" 
      type = "int" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "parceiro" {
  name          = "parceiro"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/parceiro/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "parceiro"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_parceiro"   
      type = "int" 
      }
    columns { 
      name = "categoria"     
      type = "string" 
      }
    columns { 
      name = "nome"          
      type = "string" 
      }
    columns { 
      name = "telefone"      
      type = "string" 
      }
    columns { 
      name = "email"         
      type = "string" 
      }
    columns { 
      name = "endereco"      
      type = "string" 
      }
    columns { 
      name = "identificacao" 
      type = "string" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "permissao" {
  name          = "permissao"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/permissao/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "permissao"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_permissao" 
      type = "int" 
      }
    columns { 
      name = "descricao"    
      type = "string" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "prateleira" {
  name          = "prateleira"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/prateleira/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "prateleira"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_prateleira" 
      type = "int" 
      }
    columns { 
      name = "codigo"         
      type = "string" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}

resource "aws_glue_catalog_table" "saida_estoque" {
  name          = "saida_estoque"
  database_name = aws_glue_catalog_database.venuste_db.name

  storage_descriptor {
    location      = "s3://bucket-client-g3-venuste-v2/saida_estoque/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "saida_estoque"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = { "field.delim" = ";", "serialization.format" = ";" }
    }

    columns { 
      name = "id_saida_estoque"    
      type = "int" 
      }
    columns { 
      name = "data"                
      type = "string" 
      } # pode virar date
    columns { 
      name = "hora"                
      type = "string" 
      } # pode virar timestamp
    columns { 
      name = "qtd_saida"           
      type = "double" 
      }
    columns { 
      name = "motivo_saida"        
      type = "string" 
      }
    columns { 
      name = "fk_responsavel"      
      type = "int"
     }
    columns { 
      name = "fk_lote_item_estoque" 
      type = "int"
      }
    columns { 
      name = "fk_costureira"       
      type = "int" 
      }
  }

  parameters = {
    EXTERNAL = "TRUE"
    classification = "csv"
    "typeOfData"         = "file"
    "compressionType"    = "none"
    "skip.header.line.count" = "1"
  }
}