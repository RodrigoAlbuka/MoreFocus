#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
MoreFocus - Demonstração Local dos Agentes de IA
Este script simula o funcionamento dos workflows sem necessidade do n8n
"""

import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any

class APQAgent:
    """Agente de Prospecção e Qualificação"""
    
    def __init__(self):
        self.name = "APQ - Agente de Prospecção e Qualificação"
    
    def process_lead(self, lead_data: Dict[str, Any]) -> Dict[str, Any]:
        """Processa e qualifica um lead"""
        
        # Validação básica
        if not lead_data.get('company') or not lead_data.get('email'):
            return {
                'status': 'error',
                'message': 'Dados obrigatórios faltando: company e email são necessários'
            }
        
        # Qualificação do lead
        score = 0
        qualification_notes = []
        
        # Critério 1: Tamanho da empresa
        employees = lead_data.get('employees', 0)
        if employees >= 100:
            score += 30
            qualification_notes.append('Empresa de grande porte (+30 pontos)')
        elif employees >= 50:
            score += 20
            qualification_notes.append('Empresa de médio porte (+20 pontos)')
        else:
            score += 10
            qualification_notes.append('Empresa de pequeno porte (+10 pontos)')
        
        # Critério 2: Setor de atuação
        high_value_sectors = ['technology', 'finance', 'healthcare', 'manufacturing']
        sector = lead_data.get('sector', '').lower()
        if sector in high_value_sectors:
            score += 25
            qualification_notes.append(f'Setor de alto valor: {sector} (+25 pontos)')
        
        # Critério 3: Orçamento
        budget = lead_data.get('budget', 0)
        if budget >= 10000:
            score += 35
            qualification_notes.append('Orçamento alto (+35 pontos)')
        elif budget >= 5000:
            score += 25
            qualification_notes.append('Orçamento médio (+25 pontos)')
        else:
            score += 10
            qualification_notes.append('Orçamento baixo (+10 pontos)')
        
        # Critério 4: Urgência
        urgency = lead_data.get('urgency', 'low').lower()
        if urgency == 'high':
            score += 20
            qualification_notes.append('Alta urgência (+20 pontos)')
        elif urgency == 'medium':
            score += 10
            qualification_notes.append('Média urgência (+10 pontos)')
        
        # Classificação
        if score >= 80:
            classification = 'Hot Lead'
        elif score >= 60:
            classification = 'Warm Lead'
        elif score >= 40:
            classification = 'Cold Lead'
        else:
            classification = 'Low Quality Lead'
        
        # Próximas ações
        if score >= 80:
            next_actions = [
                'Agendar demo imediatamente',
                'Enviar proposta personalizada',
                'Contato telefônico em 24h'
            ]
        elif score >= 60:
            next_actions = [
                'Enviar material educativo',
                'Agendar call de descoberta',
                'Adicionar à sequência de nurturing'
            ]
        else:
            next_actions = [
                'Adicionar à lista de newsletter',
                'Enviar conteúdo de valor',
                'Reavaliar em 30 dias'
            ]
        
        return {
            'status': 'success',
            'leadId': f"LEAD_{int(time.time())}_{hash(lead_data['email']) % 10000}",
            'company': lead_data['company'],
            'email': lead_data['email'],
            'contact': lead_data.get('contact', ''),
            'phone': lead_data.get('phone', ''),
            'sector': lead_data.get('sector', ''),
            'employees': employees,
            'budget': budget,
            'urgency': urgency,
            'qualificationScore': score,
            'classification': classification,
            'qualificationNotes': qualification_notes,
            'nextActions': next_actions,
            'processedAt': datetime.now().isoformat(),
            'agent': self.name
        }

class ANEAgent:
    """Agente de Nutrição e Engajamento"""
    
    def __init__(self):
        self.name = "ANE - Agente de Nutrição e Engajamento"
    
    def process_lead(self, lead_data: Dict[str, Any]) -> Dict[str, Any]:
        """Define estratégia de nutrição para o lead"""
        
        classification = lead_data.get('classification', 'Cold Lead')
        
        # Estratégias por classificação
        strategies = {
            'Hot Lead': {
                'sequence': 'hot_lead_sequence',
                'emailCount': 3,
                'frequency': 'daily',
                'content': [
                    {
                        'day': 1,
                        'subject': f"{lead_data.get('company', 'Sua empresa')} - Proposta Personalizada de Automação",
                        'template': 'hot_lead_proposal',
                        'cta': 'Agendar Demo Executiva',
                        'priority': 'high'
                    },
                    {
                        'day': 2,
                        'subject': 'Case de Sucesso: Como empresa similar economizou 40% com automação',
                        'template': 'case_study',
                        'cta': 'Ver Mais Cases',
                        'priority': 'high'
                    },
                    {
                        'day': 3,
                        'subject': 'Última chance: Demo exclusiva para sua empresa',
                        'template': 'urgency_demo',
                        'cta': 'Agendar Agora',
                        'priority': 'urgent'
                    }
                ]
            },
            'Warm Lead': {
                'sequence': 'warm_lead_sequence',
                'emailCount': 5,
                'frequency': 'every_2_days',
                'content': [
                    {
                        'day': 1,
                        'subject': 'Bem-vindo! Como a automação pode transformar sua empresa',
                        'template': 'welcome_warm',
                        'cta': 'Baixar Guia Gratuito',
                        'priority': 'normal'
                    },
                    {
                        'day': 3,
                        'subject': '5 Processos que toda empresa deveria automatizar',
                        'template': 'educational_content',
                        'cta': 'Ler Artigo Completo',
                        'priority': 'normal'
                    },
                    {
                        'day': 5,
                        'subject': 'Calculadora ROI: Descubra quanto sua empresa pode economizar',
                        'template': 'roi_calculator',
                        'cta': 'Calcular Economia',
                        'priority': 'normal'
                    },
                    {
                        'day': 7,
                        'subject': 'Webinar exclusivo: Automação para empresas do seu setor',
                        'template': 'webinar_invite',
                        'cta': 'Inscrever-se Grátis',
                        'priority': 'normal'
                    },
                    {
                        'day': 10,
                        'subject': 'Pronto para dar o próximo passo?',
                        'template': 'gentle_cta',
                        'cta': 'Conversar com Especialista',
                        'priority': 'normal'
                    }
                ]
            },
            'Cold Lead': {
                'sequence': 'cold_lead_sequence',
                'emailCount': 7,
                'frequency': 'weekly',
                'content': [
                    {
                        'day': 1,
                        'subject': 'Obrigado pelo interesse em automação!',
                        'template': 'welcome_cold',
                        'cta': 'Acessar Recursos Gratuitos',
                        'priority': 'low'
                    },
                    {
                        'day': 7,
                        'subject': 'Newsletter: Tendências em Automação - Janeiro 2024',
                        'template': 'newsletter',
                        'cta': 'Ler Newsletter',
                        'priority': 'low'
                    },
                    {
                        'day': 14,
                        'subject': 'Dica da semana: Como identificar processos para automatizar',
                        'template': 'weekly_tip',
                        'cta': 'Ver Mais Dicas',
                        'priority': 'low'
                    }
                ]
            }
        }
        
        strategy = strategies.get(classification, strategies['Cold Lead'])
        
        # Tracking data
        tracking_data = {
            'leadId': lead_data.get('leadId'),
            'campaignId': f"ANE_{classification.replace(' ', '_')}_{int(time.time())}",
            'source': lead_data.get('source', 'unknown'),
            'utmSource': 'morefocus',
            'utmMedium': 'email',
            'utmCampaign': strategy['sequence']
        }
        
        return {
            'status': 'success',
            'leadId': lead_data.get('leadId'),
            'company': lead_data.get('company'),
            'email': lead_data.get('email'),
            'contact': lead_data.get('contact'),
            'classification': classification,
            'score': lead_data.get('score', 0),
            'strategy': strategy,
            'tracking': tracking_data,
            'scheduledEmails': strategy['emailCount'],
            'estimatedDuration': f"{strategy['emailCount'] * (1 if strategy['frequency'] == 'daily' else 2 if strategy['frequency'] == 'every_2_days' else 7)} dias",
            'processedAt': datetime.now().isoformat(),
            'agent': self.name
        }

class AVCAgent:
    """Agente de Vendas e Conversão"""
    
    def __init__(self):
        self.name = "AVC - Agente de Vendas e Conversão"
    
    def process_opportunity(self, lead_data: Dict[str, Any]) -> Dict[str, Any]:
        """Processa oportunidade de venda"""
        
        sales_stage = lead_data.get('salesStage', 'initial_contact')
        lead_score = lead_data.get('score', 0)
        budget = lead_data.get('budget', 0)
        employees = lead_data.get('employees', 50)
        
        # Estratégias por estágio
        stage_strategies = {
            'initial_contact': {
                'stage': 'Contato Inicial',
                'objective': 'Qualificar necessidades e agendar demo',
                'timeline': '3-5 dias',
                'nextStage': 'discovery_call'
            },
            'discovery_call': {
                'stage': 'Call de Descoberta',
                'objective': 'Entender pain points e definir solução',
                'timeline': '1-2 semanas',
                'nextStage': 'demo_presentation'
            },
            'demo_presentation': {
                'stage': 'Demonstração',
                'objective': 'Mostrar solução personalizada',
                'timeline': '1 semana',
                'nextStage': 'proposal_generation'
            },
            'proposal_generation': {
                'stage': 'Geração de Proposta',
                'objective': 'Criar proposta comercial detalhada',
                'timeline': '3-5 dias',
                'nextStage': 'negotiation'
            },
            'negotiation': {
                'stage': 'Negociação',
                'objective': 'Finalizar termos e fechar venda',
                'timeline': '1-2 semanas',
                'nextStage': 'closing'
            },
            'closing': {
                'stage': 'Fechamento',
                'objective': 'Finalizar venda e iniciar onboarding',
                'timeline': '3-7 dias',
                'nextStage': 'won'
            }
        }
        
        strategy = stage_strategies.get(sales_stage, stage_strategies['initial_contact'])
        
        # Calcular probabilidade de fechamento
        stage_probabilities = {
            'initial_contact': 10,
            'discovery_call': 25,
            'demo_presentation': 45,
            'proposal_generation': 65,
            'negotiation': 80,
            'closing': 95
        }
        
        probability = stage_probabilities.get(sales_stage, 10)
        if lead_score > 80:
            probability += 10
        if budget > 10000:
            probability += 5
        if lead_data.get('urgency') == 'high':
            probability += 10
        
        probability = min(probability, 95)
        
        # Gerar proposta se necessário
        proposal_data = {}
        if sales_stage == 'proposal_generation':
            base_price = 5000
            complexity_multiplier = 1.5 if employees > 200 else 1.2 if employees > 50 else 1
            monthly_price = int(base_price * (employees / 50) * complexity_multiplier)
            
            proposal_data = {
                'packageType': 'Enterprise' if employees > 200 else 'Professional' if employees > 50 else 'Starter',
                'monthlyPrice': monthly_price,
                'annualPrice': int(monthly_price * 12 * 0.85),  # 15% desconto
                'setupFee': int(monthly_price * 0.5),
                'savings': int(monthly_price * 12 * 0.15),
                'implementation': {
                    'duration': '8-12 semanas' if employees > 200 else '4-8 semanas' if employees > 50 else '2-4 semanas',
                    'phases': ['Análise', 'Desenvolvimento', 'Testes', 'Deploy', 'Treinamento']
                },
                'roi': {
                    'timeToROI': '3-6 meses',
                    'expectedSavings': monthly_price * 3,
                    'efficiencyGain': '40-60%'
                }
            }
        
        # Insights de vendas
        sales_insights = {
            'dealHealth': 'Excelente' if probability > 70 else 'Boa' if probability > 50 else 'Média' if probability > 30 else 'Baixa',
            'keyRisks': self._identify_risks(lead_data, probability),
            'recommendations': [
                f'Focar em: {strategy["objective"]}',
                'Manter follow-up consistente',
                'Demonstrar ROI claro'
            ],
            'nextBestAction': f'Executar: {strategy["objective"]}'
        }
        
        return {
            'status': 'success',
            'leadId': lead_data.get('leadId'),
            'opportunityId': f"OPP_{int(time.time())}_{hash(lead_data.get('email', '')) % 10000}",
            'company': lead_data.get('company'),
            'email': lead_data.get('email'),
            'contact': lead_data.get('contact'),
            'currentStage': sales_stage,
            'salesStrategy': strategy,
            'closingProbability': probability,
            'proposalData': proposal_data,
            'salesInsights': sales_insights,
            'estimatedValue': max(budget, employees * 100),
            'timeline': strategy['timeline'],
            'processedAt': datetime.now().isoformat(),
            'agent': self.name
        }
    
    def _identify_risks(self, data: Dict[str, Any], probability: int) -> List[str]:
        """Identifica riscos da oportunidade"""
        risks = []
        if probability < 50:
            risks.append('Baixa probabilidade de fechamento')
        if not data.get('budget') or data.get('budget', 0) < 5000:
            risks.append('Orçamento limitado')
        if data.get('urgency') == 'low':
            risks.append('Baixa urgência do cliente')
        return risks

def demo_single_agent():
    """Demonstra funcionamento de um agente individual"""
    print("🤖 Demonstração - Agente Individual")
    print("=" * 50)
    
    # Dados de teste
    test_lead = {
        "company": "TechCorp Inovação",
        "email": "contato@techcorp.com",
        "contact": "João Silva",
        "phone": "+55 11 99999-9999",
        "sector": "technology",
        "employees": 150,
        "budget": 15000,
        "urgency": "high",
        "source": "website_form"
    }
    
    print(f"📋 Lead de entrada: {test_lead['company']}")
    
    # Teste APQ
    apq = APQAgent()
    apq_result = apq.process_lead(test_lead)
    
    print(f"\n🔍 {apq.name}")
    print(f"   📊 Score: {apq_result['qualificationScore']}/100")
    print(f"   🎯 Classificação: {apq_result['classification']}")
    print(f"   📝 Próximas ações: {len(apq_result['nextActions'])}")
    
    return apq_result

def demo_integrated_flow():
    """Demonstra fluxo integrado dos agentes"""
    print("\n🔄 Demonstração - Fluxo Integrado")
    print("=" * 50)
    
    # Lead de alta qualidade
    premium_lead = {
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
    
    print(f"🚀 Iniciando fluxo com: {premium_lead['company']}")
    
    # Passo 1: APQ
    print(f"\n1️⃣ APQ - Qualificação")
    apq = APQAgent()
    apq_result = apq.process_lead(premium_lead)
    print(f"   📊 Score: {apq_result['qualificationScore']}")
    print(f"   🎯 Classificação: {apq_result['classification']}")
    
    # Passo 2: ANE
    print(f"\n2️⃣ ANE - Nutrição")
    ane = ANEAgent()
    ane_result = ane.process_lead(apq_result)
    print(f"   📧 Emails programados: {ane_result['scheduledEmails']}")
    print(f"   ⏱️ Duração: {ane_result['estimatedDuration']}")
    print(f"   🎯 Estratégia: {ane_result['strategy']['sequence']}")
    
    # Passo 3: AVC
    print(f"\n3️⃣ AVC - Vendas")
    avc_data = {**ane_result, 'salesStage': 'proposal_generation'}
    avc = AVCAgent()
    avc_result = avc.process_opportunity(avc_data)
    print(f"   💰 Probabilidade: {avc_result['closingProbability']}%")
    print(f"   💵 Valor estimado: ${avc_result['estimatedValue']:,}")
    print(f"   📋 Estágio: {avc_result['salesStrategy']['stage']}")
    
    if avc_result['proposalData']:
        proposal = avc_result['proposalData']
        print(f"   📄 Proposta: {proposal['packageType']}")
        print(f"   💰 Preço mensal: ${proposal['monthlyPrice']:,}")
        print(f"   💾 Setup: ${proposal['setupFee']:,}")
        print(f"   💸 Economia anual: ${proposal['savings']:,}")
    
    print(f"\n✅ Fluxo completo executado!")
    print(f"📈 Jornada: APQ → ANE → AVC")
    print(f"🎯 Resultado: {avc_result['salesInsights']['dealHealth']} oportunidade")
    
    return {
        'apq': apq_result,
        'ane': ane_result,
        'avc': avc_result
    }

def demo_multiple_leads():
    """Demonstra processamento de múltiplos leads"""
    print("\n📊 Demonstração - Múltiplos Leads")
    print("=" * 50)
    
    test_leads = [
        {
            "company": "Startup Ágil",
            "email": "ceo@startup.com",
            "sector": "technology",
            "employees": 25,
            "budget": 3000,
            "urgency": "medium"
        },
        {
            "company": "Indústria Tradicional",
            "email": "ti@industria.com",
            "sector": "manufacturing",
            "employees": 300,
            "budget": 25000,
            "urgency": "low"
        },
        {
            "company": "Fintech Inovadora",
            "email": "cto@fintech.com",
            "sector": "finance",
            "employees": 80,
            "budget": 12000,
            "urgency": "high"
        }
    ]
    
    apq = APQAgent()
    results = []
    
    for i, lead in enumerate(test_leads, 1):
        print(f"\n📋 Lead {i}: {lead['company']}")
        result = apq.process_lead(lead)
        results.append(result)
        
        print(f"   📊 Score: {result['qualificationScore']}")
        print(f"   🎯 Classificação: {result['classification']}")
        print(f"   👥 Funcionários: {result['employees']}")
        print(f"   💰 Orçamento: ${result['budget']:,}")
    
    # Estatísticas
    classifications = [r['classification'] for r in results]
    scores = [r['qualificationScore'] for r in results]
    
    print(f"\n📈 Estatísticas:")
    print(f"   🔥 Hot Leads: {classifications.count('Hot Lead')}")
    print(f"   🌡️ Warm Leads: {classifications.count('Warm Lead')}")
    print(f"   ❄️ Cold Leads: {classifications.count('Cold Lead')}")
    print(f"   📊 Score médio: {sum(scores) / len(scores):.1f}")
    
    return results

def main():
    """Função principal da demonstração"""
    print("🚀 MoreFocus - Demonstração dos Agentes de IA")
    print("=" * 60)
    print(f"⏰ Iniciado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    print("Esta demonstração simula o funcionamento dos agentes")
    print("sem necessidade de importar workflows no n8n.")
    print()
    
    try:
        # Demonstração individual
        demo_single_agent()
        
        # Demonstração integrada
        demo_integrated_flow()
        
        # Demonstração múltiplos leads
        demo_multiple_leads()
        
        print(f"\n" + "=" * 60)
        print("✅ DEMONSTRAÇÃO CONCLUÍDA COM SUCESSO!")
        print("=" * 60)
        print()
        print("🎯 Próximos passos para implementação real:")
        print("   1. Importar workflows JSON no n8n")
        print("   2. Ativar workflows na interface")
        print("   3. Configurar integrações (email, CRM)")
        print("   4. Testar webhooks via HTTP")
        print("   5. Implementar banco de dados")
        print()
        print("📁 Arquivos disponíveis:")
        print("   • workflows/APQ_Agente_Prospeccao.json")
        print("   • workflows/ANE_Agente_Nutricao.json")
        print("   • workflows/AVC_Agente_Vendas.json")
        print("   • test_workflows.py (testes HTTP)")
        print("   • demo_workflows.py (esta demonstração)")
        
    except KeyboardInterrupt:
        print(f"\n⚠️ Demonstração interrompida pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante demonstração: {str(e)}")
    
    print(f"\n⏰ Finalizado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()

