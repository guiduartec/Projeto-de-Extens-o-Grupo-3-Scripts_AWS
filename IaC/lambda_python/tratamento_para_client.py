import pandas as pd
import os
from datetime import datetime

def calculate_monthly_averages():
    # Configuração de caminhos
    base_path = os.path.dirname(os.path.dirname(__file__))
    input_path = os.path.join(base_path, 'main_terraform', 'weather_processed.csv')
    output_path = os.path.join(base_path, 'main_terraform', 'monthly_averages.csv')
    
    try:
        # Leitura do CSV processado
        df = pd.read_csv(input_path)
        
        # Converter timestamp para datetime para extrair mês
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df['mes'] = df['timestamp'].dt.month
        
        # Converter temperatura para numérico, ignorando 'N/A'
        df['temperatura'] = pd.to_numeric(df['temperatura'], errors='coerce')
        
        # Calcular médias mensais por estação
        monthly_avg = df.groupby(['estacao', 'mes'])['temperatura'].agg([
            ('temperatura_media', 'mean')
        ]).round(2).reset_index()
        
        # Ordenar por estação e mês
        monthly_avg = monthly_avg.sort_values(['estacao', 'mes'])
        
        # Adicionar nome do mês
        meses = {
            1: 'Janeiro', 2: 'Fevereiro', 3: 'Março', 
            4: 'Abril', 5: 'Maio', 6: 'Junho',
            7: 'Julho', 8: 'Agosto', 9: 'Setembro',
            10: 'Outubro', 11: 'Novembro', 12: 'Dezembro'
        }
        monthly_avg['nome_mes'] = monthly_avg['mes'].map(meses)
        
        # Reordenar colunas
        monthly_avg = monthly_avg[['estacao', 'mes', 'nome_mes', 'temperatura_media']]
        
        # Salvar resultado
        monthly_avg.to_csv(output_path, index=False)
        
        # Imprimir resultados
        print("\nMédias mensais de temperatura por estação:")
        print("\nEstação A771:")
        print(monthly_avg[monthly_avg['estacao'] == 'A771'].to_string(index=False))
        print("\nEstação A701:")
        print(monthly_avg[monthly_avg['estacao'] == 'A701'].to_string(index=False))
        
        # Calcular e mostrar médias anuais
        print("\nMédias anuais por estação:")
        annual_avg = df.groupby('estacao')['temperatura'].mean().round(2)
        for estacao, media in annual_avg.items():
            print(f"Estação {estacao}: {media}°C")
        
        return output_path
        
    except Exception as e:
        raise Exception(f"Erro ao processar dados: {str(e)}")

if __name__ == "__main__":
    try:
        output_file = calculate_monthly_averages()
        print(f"\nArquivo de saída gerado em: {output_file}")
    except Exception as e:
        print(f"Erro ao processar dados: {str(e)}")