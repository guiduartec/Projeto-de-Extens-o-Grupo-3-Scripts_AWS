#!/usr/bin/env python3
"""
Converte um CSV separado por ponto-e-vírgula para um arquivo SQLite
e gera uma coluna `time` a partir da coluna `mes` (primeiro dia do mês).

Uso:
  python convert_csv_to_sqlite.py --input path/to/csv_client.csv --output data.db --table csv_client --year 2024

O script tenta lidar com decimais com vírgula (23,14 -> 23.14) e remove colunas vazias.
"""
import argparse
import pandas as pd
from sqlalchemy import create_engine
import sys
import sqlite3


def main():
    parser = argparse.ArgumentParser(description="Converter CSV (sep=';') para SQLite e criar coluna time")
    parser.add_argument("--input", required=True, help="Caminho do CSV de entrada")
    parser.add_argument("--output", default="data.db", help="Arquivo SQLite de saída")
    parser.add_argument("--table", default="csv_client", help="Nome da tabela no SQLite")
    parser.add_argument("--year", type=int, default=2024, help="Ano a usar ao gerar a coluna time")
    parser.add_argument("--preview", action="store_true", help="Após criar o DB, imprime as primeiras linhas da tabela")
    parser.add_argument("--preview-rows", type=int, default=10, help="Número de linhas a mostrar com --preview")
    args = parser.parse_args()

    try:
        df = pd.read_csv(args.input, sep=';', encoding='utf-8', dtype=str)
    except Exception as e:
        print(f"Erro ao ler CSV: {e}", file=sys.stderr)
        sys.exit(2)

    # remover colunas vazias (nomes vazios ou apenas espaços)
    # Garantir que os nomes são strings antes de usar .str
    df.columns = df.columns.astype(str).str.strip()
    mask = df.columns != ''
    df = df.loc[:, mask]

    # converter valores numéricos quando possível (tenta trocar vírgula por ponto)
    for col in df.columns:
        # replace só em strings
        try:
            df[col] = df[col].str.replace(',', '.')
        except Exception:
            pass

    # criar coluna 'time' a partir do mês (coluna 'mes') usando o primeiro dia do mês
    if 'mes' in df.columns:
        try:
            df['mes'] = df['mes'].astype(int)
            df['time'] = pd.to_datetime(df['mes'].apply(lambda m: f"{args.year}-{m:02d}-01"))
        except Exception as e:
            print(f"Erro ao criar coluna 'time' a partir de 'mes': {e}", file=sys.stderr)
            sys.exit(3)
    else:
        print("Arquivo não contém coluna 'mes'. Adapte o script para gerar timestamps.", file=sys.stderr)
        sys.exit(4)

    # renomear coluna de temperatura (se existir) para 'temperatura'
    if 'temperatura_media' in df.columns:
        df['temperatura'] = pd.to_numeric(df['temperatura_media'], errors='coerce')
    else:
        # tenta identificar a primeira coluna numérica como value
        for col in df.columns:
            if col in ('time', 'mes', 'estacao', 'nome_mes'):
                continue
            # tenta converter
            try:
                tmp = pd.to_numeric(df[col], errors='coerce')
                if tmp.notna().any():
                    df['temperatura'] = tmp
                    break
            except Exception:
                continue

    # selecionar colunas úteis para gravar
    cols_keep = ['time', 'temperatura', 'estacao', 'nome_mes', 'mes']
    cols_present = [c for c in cols_keep if c in df.columns]
    df_out = df[cols_present]

    # gravar no SQLite
    try:
        engine = create_engine(f"sqlite:///{args.output}")
        df_out.to_sql(args.table, engine, if_exists='replace', index=False)
        print(f"Gravado {len(df_out)} linhas em {args.output} tabela {args.table}")
    except Exception as e:
        print(f"Erro ao gravar SQLite: {e}", file=sys.stderr)
        sys.exit(5)

    # Se solicitado, mostrar um preview das primeiras linhas da tabela criada
    if getattr(args, 'preview', False):
        try:
            con = sqlite3.connect(args.output)
            df_preview = pd.read_sql_query(f"SELECT * FROM {args.table} LIMIT {int(args.preview_rows)}", con)
            print('\nPreview das primeiras linhas:')
            print(df_preview.to_string(index=False))
            con.close()
        except Exception as e:
            print(f"Erro ao gerar preview: {e}", file=sys.stderr)

    


if __name__ == '__main__':
    main()
