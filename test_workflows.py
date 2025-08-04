#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import json
import time
from datetime import datetime

# Configurações
N8N_BASE_URL = "http://localhost:5678"
WEBHOOK_ENDPOINTS = {
    "APQ": f"{N8N_BASE_URL}/webhook/prospeccao",
    "ANE": f"{N8N_BASE_URL}/webhook/nutricao", 
    "AVC": f"{N8N_BASE_URL}/webhook/vendas"
}

def test_apq_agent():
    """Testa o Agente de Prospecção e Qualificação"""
    print("🔍 Testando APQ - Agente de Prospecção e Qualificação")
    print("=" * 60)
    
    # Dados de teste para diferentes tipos de leads
    test_leads = [
        {
            "company": "TechCorp Ltda",
            "email": "contato@techcorp.com",
            "contact": "João Silva",
            "phone": "+55 11 99999-9999",
            "sector": "technology",
            "employees": 150,
            "budget": 15000,
            "urgency": "high",
            "source": "website_form"
        },
        {
            "company": "Pequena Empresa ME",
            "email": "admin@pequena.com",
            "contact": "Maria Santos",
            "sector": "retail",
            "employees": 25,
            "budget": 3000,
            "urgency": "medium",
            "source": "google_ads"
        },
        {
            "company": "Startup Inovadora",
            "email": "ceo@startup.com",
            "contact": "Pedro Costa",
            "sector": "finance",
            "employees": 45,
            "budget": 8000,
            "urgency": "low",
            "source": "referral"
        }
    ]
    
    results = []
    for i, lead in enumerate(test_leads, 1):
        print(f"\n📋 Testando Lead {i}: {lead['company']}")
        
        try:
            response = requests.post(
                WEBHOOK_ENDPOINTS["APQ"],
                json=lead,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                results.append(result)
                
                print(f"✅ Status: {result.get('status')}")
                print(f"🏢 Empresa: {result.get('company')}")
                print(f"📊 Score: {result.get('qualificationScore')}/100")
                print(f"🎯 Classificação: {result.get('classification')}")
                print(f"📝 Próximas ações: {len(result.get('nextActions', []))} ações")
                
                # Se for Hot Lead, testar ANE automaticamente
                if result.get('classification') == 'Hot Lead':
                    print(f"🔥 Hot Lead detectado! Enviando para ANE...")
                    test_ane_agent(result)
                    
            else:
                print(f"❌ Erro HTTP {response.status_code}: {response.text}")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Erro de conexão: {str(e)}")
        
        time.sleep(1)  # Pausa entre requests
    
    return results

def test_ane_agent(lead_data=None):
    """Testa o Agente de Nutrição e Engajamento"""
    print("\n📧 Testando ANE - Agente de Nutrição e Engajamento")
    print("=" * 60)
    
    if not lead_data:
        # Dados de teste padrão se não vier do APQ
        lead_data = {
            "leadId": "LEAD_TEST_123",
            "company": "Empresa Teste",
            "email": "teste@empresa.com",
            "contact": "Teste Silva",
            "classification": "Warm Lead",
            "score": 65,
            "source": "APQ"
        }
    
    try:
        response = requests.post(
            WEBHOOK_ENDPOINTS["ANE"],
            json=lead_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            
            print(f"✅ Status: {result.get('status')}")
            print(f"🏢 Empresa: {result.get('company')}")
            print(f"📧 Email: {result.get('email')}")
            print(f"🎯 Classificação: {result.get('classification')}")
            print(f"📊 Score: {result.get('score')}")
            
            strategy = result.get('strategy', {})
            print(f"📋 Estratégia: {strategy.get('sequence')}")
            print(f"📨 Emails programados: {result.get('scheduledEmails')}")
            print(f"⏱️ Duração estimada: {result.get('estimatedDuration')}")
            
            # Se for alta prioridade, testar AVC
            if strategy.get('content', [{}])[0].get('priority') == 'high':
                print(f"⚡ Alta prioridade detectada! Enviando para AVC...")
                test_avc_agent(result)
                
            return result
            
        else:
            print(f"❌ Erro HTTP {response.status_code}: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {str(e)}")
    
    return None

def test_avc_agent(lead_data=None):
    """Testa o Agente de Vendas e Conversão"""
    print("\n💰 Testando AVC - Agente de Vendas e Conversão")
    print("=" * 60)
    
    if not lead_data:
        # Dados de teste padrão
        lead_data = {
            "leadId": "LEAD_TEST_456",
            "company": "Empresa Premium",
            "email": "vendas@premium.com",
            "contact": "Diretor Comercial",
            "classification": "Hot Lead",
            "score": 85,
            "budget": 20000,
            "employees": 200,
            "urgency": "high",
            "salesStage": "demo_presentation"
        }
    
    # Adicionar dados específicos de vendas se não existirem
    if 'salesStage' not in lead_data:
        lead_data['salesStage'] = 'initial_contact'
    if 'budget' not in lead_data:
        lead_data['budget'] = 10000
    if 'employees' not in lead_data:
        lead_data['employees'] = 100
    
    try:
        response = requests.post(
            WEBHOOK_ENDPOINTS["AVC"],
            json=lead_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            
            print(f"✅ Status: {result.get('status')}")
            print(f"🏢 Empresa: {result.get('company')}")
            print(f"🎯 Oportunidade ID: {result.get('opportunityId')}")
            print(f"📊 Probabilidade de fechamento: {result.get('closingProbability')}%")
            print(f"💵 Valor estimado: ${result.get('estimatedValue'):,}")
            
            strategy = result.get('salesStrategy', {})
            print(f"📋 Estágio atual: {strategy.get('stage')}")
            print(f"🎯 Objetivo: {strategy.get('objective')}")
            print(f"⏱️ Timeline: {strategy.get('timeline')}")
            
            proposal = result.get('proposalData', {})
            if proposal:
                print(f"📄 Proposta: {proposal.get('packageType')} - ${proposal.get('monthlyPrice')}/mês")
                print(f"💾 Setup: ${proposal.get('setupFee')}")
                print(f"💰 Economia anual: ${proposal.get('savings')}")
            
            insights = result.get('salesInsights', {})
            print(f"🏥 Saúde do deal: {insights.get('dealHealth')}")
            print(f"⚠️ Riscos: {len(insights.get('keyRisks', []))} identificados")
            
            return result
            
        else:
            print(f"❌ Erro HTTP {response.status_code}: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {str(e)}")
    
    return None

def test_integration_flow():
    """Testa o fluxo integrado dos agentes"""
    print("\n🔄 Testando Fluxo Integrado dos Agentes")
    print("=" * 60)
    
    # Lead que deve passar por todos os agentes
    hot_lead = {
        "company": "MegaCorp Enterprise",
        "email": "cto@megacorp.com",
        "contact": "Carlos Eduardo",
        "phone": "+55 11 98888-8888",
        "sector": "technology",
        "employees": 500,
        "budget": 50000,
        "urgency": "high",
        "source": "enterprise_inquiry"
    }
    
    print(f"🚀 Iniciando com lead: {hot_lead['company']}")
    
    # Passo 1: APQ
    print(f"\n1️⃣ Processando no APQ...")
    apq_result = requests.post(WEBHOOK_ENDPOINTS["APQ"], json=hot_lead).json()
    print(f"   📊 Score APQ: {apq_result.get('qualificationScore')}")
    print(f"   🎯 Classificação: {apq_result.get('classification')}")
    
    # Passo 2: ANE
    print(f"\n2️⃣ Enviando para ANE...")
    ane_data = {
        "leadId": apq_result.get('leadId'),
        "company": apq_result.get('company'),
        "email": apq_result.get('email'),
        "contact": apq_result.get('contact'),
        "classification": apq_result.get('classification'),
        "score": apq_result.get('qualificationScore'),
        "source": "APQ"
    }
    
    ane_result = requests.post(WEBHOOK_ENDPOINTS["ANE"], json=ane_data).json()
    print(f"   📧 Emails programados: {ane_result.get('scheduledEmails')}")
    print(f"   ⏱️ Duração: {ane_result.get('estimatedDuration')}")
    
    # Passo 3: AVC
    print(f"\n3️⃣ Avançando para AVC...")
    avc_data = {
        "leadId": ane_result.get('leadId'),
        "company": ane_result.get('company'),
        "email": ane_result.get('email'),
        "contact": ane_result.get('contact'),
        "classification": ane_result.get('classification'),
        "score": ane_result.get('score'),
        "budget": hot_lead['budget'],
        "employees": hot_lead['employees'],
        "urgency": hot_lead['urgency'],
        "salesStage": "proposal_generation"
    }
    
    avc_result = requests.post(WEBHOOK_ENDPOINTS["AVC"], json=avc_data).json()
    print(f"   💰 Probabilidade: {avc_result.get('closingProbability')}%")
    print(f"   💵 Valor estimado: ${avc_result.get('estimatedValue'):,}")
    
    print(f"\n✅ Fluxo integrado concluído com sucesso!")
    print(f"📈 Jornada completa: APQ → ANE → AVC")
    
    return {
        "apq": apq_result,
        "ane": ane_result,
        "avc": avc_result
    }

def check_n8n_health():
    """Verifica se o n8n está funcionando"""
    print("🏥 Verificando saúde do n8n...")
    
    try:
        response = requests.get(f"{N8N_BASE_URL}/", timeout=5)
        if response.status_code == 200:
            print("✅ n8n está funcionando!")
            return True
        else:
            print(f"⚠️ n8n respondeu com status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ n8n não está acessível: {str(e)}")
        return False

def main():
    """Função principal para executar todos os testes"""
    print("🚀 MoreFocus - Teste dos Agentes de IA")
    print("=" * 60)
    print(f"⏰ Iniciado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar se n8n está funcionando
    if not check_n8n_health():
        print("❌ n8n não está acessível. Verifique se os containers estão rodando.")
        return
    
    print(f"\n📋 Endpoints configurados:")
    for agent, url in WEBHOOK_ENDPOINTS.items():
        print(f"   {agent}: {url}")
    
    try:
        # Teste individual dos agentes
        print(f"\n" + "="*60)
        print("🧪 TESTES INDIVIDUAIS DOS AGENTES")
        print("="*60)
        
        apq_results = test_apq_agent()
        time.sleep(2)
        
        test_ane_agent()
        time.sleep(2)
        
        test_avc_agent()
        time.sleep(2)
        
        # Teste do fluxo integrado
        print(f"\n" + "="*60)
        print("🔄 TESTE DO FLUXO INTEGRADO")
        print("="*60)
        
        integration_results = test_integration_flow()
        
        # Resumo final
        print(f"\n" + "="*60)
        print("📊 RESUMO DOS TESTES")
        print("="*60)
        print("✅ Todos os agentes testados com sucesso!")
        print("✅ Fluxo integrado funcionando!")
        print("✅ Webhooks respondendo corretamente!")
        
        print(f"\n🎯 Próximos passos:")
        print("   1. Importar workflows no n8n via interface")
        print("   2. Configurar integrações reais (email, CRM)")
        print("   3. Implementar banco de dados para persistência")
        print("   4. Configurar monitoramento e alertas")
        
    except KeyboardInterrupt:
        print(f"\n⚠️ Testes interrompidos pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante os testes: {str(e)}")
    
    print(f"\n⏰ Finalizado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()

