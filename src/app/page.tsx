'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Zap, Database, FileCheck, Sparkles, ArrowRight, CheckCircle2, MessageCircle, Mail, FlaskConical, Rocket } from 'lucide-react'
import { useSimulator } from '@/contexts/SimulatorContext'
import { SimulatorForm } from '@/components/form/SimulatorForm'
import { LiveBrief } from '@/components/form/LiveBrief'
import { GlassCard } from '@/components/common/GlassCard'
import { GlowButton } from '@/components/common/GlowButton'
import { NeonBadge } from '@/components/common/NeonBadge'
import { TimelineStep } from '@/components/common/TimelineStep'
import { SectionHeader } from '@/components/common/SectionHeader'
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'

export default function HomePage() {
  const { environment, setEnvironment, submissionCount } = useSimulator()

  return (
    <div className="min-h-screen bg-brand-offWhite">
      {/* Hero Section */}
      <section className="relative overflow-hidden py-16 md:py-24 px-4">
        {/* Animated Background */}
        <div className="absolute inset-0">
          <motion.div
            className="absolute inset-0 bg-gradient-to-br from-blue-600/10 via-purple-600/10 to-cyan-600/10"
            animate={{
              backgroundPosition: ['0% 0%', '100% 100%'],
            }}
            transition={{
              duration: 20,
              repeat: Infinity,
              repeatType: 'reverse',
            }}
          />
          {/* Floating orbs */}
          <motion.div
            className="absolute top-20 left-10 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl"
            animate={{
              x: [0, 100, 0],
              y: [0, 50, 0],
            }}
            transition={{
              duration: 15,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
          <motion.div
            className="absolute bottom-20 right-10 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl"
            animate={{
              x: [0, -80, 0],
              y: [0, -60, 0],
            }}
            transition={{
              duration: 18,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
        </div>
        
        <div className="container mx-auto max-w-7xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center"
          >
            {/* Main Title */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="mb-6"
            >
              <h1 className="text-4xl sm:text-5xl md:text-7xl lg:text-8xl font-bold mb-4 leading-tight">
                <span className="inline-block">
                  <span className="text-gradient bg-clip-text text-transparent bg-gradient-to-r from-blue-500 via-purple-500 to-cyan-500 animate-gradient">LunarAI Beauty</span>
                </span>
                <br />
                <span className="text-brand-secondary text-3xl sm:text-4xl md:text-6xl lg:text-7xl">Business Analysis</span>
              </h1>
            </motion.div>

            {/* Subtitle */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4, duration: 0.6 }}
              className="text-lg sm:text-xl md:text-2xl text-brand-primary max-w-4xl mx-auto mb-10 leading-relaxed px-4"
            >
              Platform ideasi produk kosmetik berbasis AI untuk brand owner Indonesia
              <br className="hidden sm:block" />
              <span className="inline-flex items-center gap-2 mt-2">
                <span className="inline-block w-2 h-2 bg-blue-500 rounded-full animate-pulse"></span>
                Mudah
                <span className="text-brand-lightGray mx-2">•</span>
                <span className="inline-block w-2 h-2 bg-purple-500 rounded-full animate-pulse" style={{animationDelay: '0.3s'}}></span>
                Cepat
                <span className="text-brand-lightGray mx-2">•</span>
                <span className="inline-block w-2 h-2 bg-cyan-500 rounded-full animate-pulse" style={{animationDelay: '0.6s'}}></span>
                Evidence-Based
              </span>
            </motion.p>

            {/* Badges */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6, duration: 0.6 }}
              className="flex flex-wrap items-center justify-center gap-3 md:gap-4"
            >
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <NeonBadge variant="blue" pulse>
                  <Sparkles className="h-3 w-3" />
                  AI-Powered
                </NeonBadge>
              </motion.div>
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <NeonBadge variant="cyan">
                  <CheckCircle2 className="h-3 w-3" />
                  {submissionCount} Submissions
                </NeonBadge>
              </motion.div>
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <NeonBadge variant="gray">
                  <FlaskConical className="h-3 w-3" />
                  Bilingual Support
                </NeonBadge>
              </motion.div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Simulator Workspace */}
      <section className="py-12 px-4">
        <div className="container mx-auto max-w-7xl">
          <GlassCard className="mb-8">
            <div className="flex flex-col md:flex-row items-center justify-between gap-4 mb-6">
              <div>
                <h2 className="text-2xl font-bold text-brand-secondary mb-2">Skincare Formula Engine</h2>
                <p className="text-sm text-brand-primary">Fill in your product details to generate a comprehensive brief</p>
              </div>
              
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <span className="text-sm text-brand-primary">env:</span>
                  <ToggleGroup
                    type="single"
                    value={environment}
                    onValueChange={(value: 'test' | 'production') => value && setEnvironment(value)}
                  >
                    <ToggleGroupItem value="test" className="glass-effect flex items-center gap-2">
                      <FlaskConical className="h-4 w-4" />
                      
                    </ToggleGroupItem>
                    <ToggleGroupItem value="production" className="glass-effect flex items-center gap-2">
                      <Rocket className="h-4 w-4" />
                      
                    </ToggleGroupItem>
                  </ToggleGroup>
                </div>
                
                <NeonBadge variant={environment === 'test' ? 'cyan' : 'blue'} pulse>
                  {environment === 'test' ? 'Test Mode' : 'Production'}
                </NeonBadge>
              </div>
            </div>
          </GlassCard>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Form Column */}
            <div className="lg:col-span-2">
              <SimulatorForm />
            </div>

            {/* Live Preview Column */}
            <div className="lg:col-span-1">
              <div className="sticky top-4">
                <h3 className="text-lg font-semibold text-brand-secondary mb-4">Live Brief Preview</h3>
                <LiveBrief />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-24 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 via-purple-500/5 to-cyan-500/5" />
        <div className="container mx-auto max-w-7xl relative z-10">
          <SectionHeader
            title="Platform Features"
            subtitle="Accelerate product development with intelligent automation"
            centered
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-cyan-500/20 rounded-2xl blur-xl group-hover:blur-2xl transition-all" />
              <GlassCard className="relative border-2 border-blue-500/30 hover:border-blue-500/60 transition-all">
                <div className="p-2 bg-blue-500/10 rounded-xl w-fit mb-4">
                  <Zap className="h-10 w-10 text-blue-500" />
                </div>
                <h3 className="text-2xl font-bold text-brand-secondary mb-3">AI Formulation Engine</h3>
                <p className="text-brand-primary leading-relaxed">
                  Intelligent ingredient pairing, stability prediction, and regulatory compliance checks powered by machine learning
                </p>
              </GlassCard>
            </div>

            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-2xl blur-xl group-hover:blur-2xl transition-all" />
              <GlassCard className="relative border-2 border-purple-500/30 hover:border-purple-500/60 transition-all">
                <div className="p-2 bg-purple-500/10 rounded-xl w-fit mb-4">
                  <Database className="h-10 w-10 text-purple-500" />
                </div>
                <h3 className="text-2xl font-bold text-brand-secondary mb-3">Workflow Orchestration</h3>
                <p className="text-brand-primary leading-relaxed">
                  Seamless integration with n8n for automated brief processing, data sync, and team collaboration
                </p>
              </GlassCard>
            </div>

            <div className="group relative">
              <div className="absolute inset-0 bg-gradient-to-br from-cyan-500/20 to-blue-500/20 rounded-2xl blur-xl group-hover:blur-2xl transition-all" />
              <GlassCard className="relative border-2 border-cyan-500/30 hover:border-cyan-500/60 transition-all">
                <div className="p-2 bg-cyan-500/10 rounded-xl w-fit mb-4">
                  <FileCheck className="h-10 w-10 text-cyan-500" />
                </div>
                <h3 className="text-2xl font-bold text-brand-secondary mb-3">Regulatory Intelligence</h3>
                <p className="text-brand-primary leading-relaxed">
                  Multi-market compliance tracking (BPOM, EU CPNP, FDA) with automated dossier generation
                </p>
              </GlassCard>
            </div>
          </div>
        </div>
      </section>

      {/* Workflow Timeline */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-5xl">
          <SectionHeader
            title="How It Works"
            subtitle="From submission to comprehensive product brief in minutes"
            centered
          />

          <div className="space-y-4">
            <TimelineStep
              icon={Sparkles}
              title="Form Submission"
              description="Fill out the comprehensive product brief with brand identity, formulation requirements, and market positioning"
              index={0}
            />
            <TimelineStep
              icon={Zap}
              title="Bolt Processing"
              description="Payload validation, schema transformation, and intelligent field enrichment"
              index={1}
            />
            <TimelineStep
              icon={Database}
              title="n8n Agent Workflow"
              description="Multi-agent orchestration: formulation analysis, market research, copywriting, packaging design"
              index={2}
            />
            <TimelineStep
              icon={Database}
              title="Neon Database Storage"
              description="Structured data persistence with versioning and audit trails"
              index={3}
            />
            <TimelineStep
              icon={FileCheck}
              title="Google Sheets Sync"
              description="Real-time collaboration dashboard for team review and approval workflows"
              index={4}
              isLast
            />
          </div>
        </div>
      </section>

      {/* Insights Deck */}
      <section className="py-20 px-4 bg-gradient-to-b from-brand-lightGray/30 to-transparent">
        <div className="container mx-auto max-w-7xl">
          <SectionHeader title="Impact Metrics" centered />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <GlassCard className="text-center">
              <div className="text-5xl font-bold text-gradient mb-2">85%</div>
              <div className="text-brand-primary">Time Saved</div>
              <p className="text-sm text-brand-primary mt-2">vs. manual brief creation</p>
            </GlassCard>

            <GlassCard className="text-center">
              <div className="text-5xl font-bold text-gradient mb-2">98%</div>
              <div className="text-brand-primary">Accuracy</div>
              <p className="text-sm text-brand-primary mt-2">regulatory compliance checks</p>
            </GlassCard>

            <GlassCard className="text-center">
              <div className="text-5xl font-bold text-gradient mb-2">48h</div>
              <div className="text-brand-primary">Fulfillment Speed</div>
              <p className="text-sm text-brand-primary mt-2">from brief to prototype</p>
            </GlassCard>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-5xl">
          <SectionHeader title="Partner Testimonials" centered />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <GlassCard>
              <div className="flex items-start gap-4">
                <div className="h-12 w-12 rounded-full bg-brand-blue/20 flex items-center justify-center flex-shrink-0">
                  <span className="text-xl font-bold text-brand-blue">A</span>
                </div>
                <div>
                  <p className="text-brand-primary italic mb-3">
                    "LBF Simulator transformed our product development cycle. We launched 3 new SKUs in half the usual time."
                  </p>
                  <div className="text-sm font-medium text-brand-secondary">Andi Wijaya</div>
                  <div className="text-xs text-brand-primary">R&D Manager, Local Beauty Brand</div>
                </div>
              </div>
            </GlassCard>

            <GlassCard>
              <div className="flex items-start gap-4">
                <div className="h-12 w-12 rounded-full bg-brand-cyan/20 flex items-center justify-center flex-shrink-0">
                  <span className="text-xl font-bold text-brand-cyan">S</span>
                </div>
                <div>
                  <p className="text-brand-primary italic mb-3">
                    "The regulatory intelligence feature saved us weeks of manual compliance research for ASEAN markets."
                  </p>
                  <div className="text-sm font-medium text-brand-secondary">Sarah Lim</div>
                  <div className="text-xs text-brand-primary">Business Development Lead</div>
                </div>
              </div>
            </GlassCard>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-24 px-4 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-blue-500/5 to-transparent" />
        <div className="container mx-auto max-w-4xl relative z-10">
          <SectionHeader title="Frequently Asked Questions" centered />

          <GlassCard className="border-2 border-blue-500/20">
            <Accordion type="single" collapsible className="w-full">
              <AccordionItem value="item-1">
                <AccordionTrigger>How long does it take to generate a product brief?</AccordionTrigger>
                <AccordionContent>
                  Most briefs are generated within 5-10 minutes after submission. Complex formulations with multiple regulatory requirements may take up to 30 minutes.
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-2">
                <AccordionTrigger>Is my product data secure?</AccordionTrigger>
                <AccordionContent>
                  Yes. All data is encrypted in transit and at rest. We use Neon Postgres with enterprise-grade security. Your formulations and brand information are never shared with third parties.
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-3">
                <AccordionTrigger>Can I edit the brief after submission?</AccordionTrigger>
                <AccordionContent>
                  Currently, you'll need to create a new submission for changes. We're working on an edit feature for the next release.
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-4">
                <AccordionTrigger>What's the difference between Test and Production mode?</AccordionTrigger>
                <AccordionContent>
                  Test mode uses a sandbox environment for experimentation without affecting production data. Production mode triggers the full workflow including Google Sheets sync and team notifications.
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-5">
                <AccordionTrigger>Do you support languages other than Indonesian?</AccordionTrigger>
                <AccordionContent>
                  The interface is bilingual (Bahasa Indonesia and English). Generated briefs can be configured for multiple languages based on your target markets.
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-6">
                <AccordionTrigger>How accurate is the regulatory compliance checking?</AccordionTrigger>
                <AccordionContent>
                  Our AI models are trained on official regulatory databases (BPOM, EU CosIng, FDA) with 98% accuracy. However, always consult with regulatory experts for final approval.
                </AccordionContent>
              </AccordionItem>
            </Accordion>
          </GlassCard>
        </div>
      </section>

      {/* Contact CTA */}
      <section className="py-24 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600/10 via-purple-600/10 to-cyan-600/10" />
        <div className="container mx-auto max-w-4xl relative z-10">
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/30 to-cyan-500/30 rounded-3xl blur-3xl" />
            <GlassCard className="relative text-center border-2 border-blue-500/30 p-12">
              <h2 className="text-4xl md:text-5xl font-bold text-brand-secondary mb-6 leading-tight">Ready to Transform Your Product Development?</h2>
              <p className="text-lg text-brand-primary mb-10 max-w-2xl mx-auto">
                Join leading Indonesian beauty brands using LunarAI Beauty to accelerate innovation
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
                <GlowButton 
                  glowColor="blue" 
                  className="min-w-[220px] text-lg py-6"
                  onClick={() => window.open('https://wa.me/6281234567890?text=Halo,%20saya%20tertarik%20untuk%20konsultasi', '_blank')}
                >
                  <MessageCircle className="mr-2 h-6 w-6" />
                  WhatsApp Us
                </GlowButton>
                <GlowButton 
                  glowColor="cyan" 
                  className="min-w-[220px] text-lg py-6"
                  onClick={() => window.open('https://calendly.com/lunarai', '_blank')}
                >
                  <Mail className="mr-2 h-6 w-6" />
                  Schedule Meeting
                </GlowButton>
              </div>
              <div className="mt-8 flex items-center justify-center gap-6 text-sm text-brand-primary">
                <div className="flex items-center gap-2">
                  <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />
                  <span>Response: &lt;24h</span>
                </div>
                <div className="h-4 w-px bg-brand-lightGray" />
                <span>Mon-Fri, 9AM-6PM WIB</span>
              </div>
            </GlassCard>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 border-t border-blue-500/20 bg-gradient-to-b from-transparent to-blue-500/5">
        <div className="container mx-auto max-w-7xl">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-center md:text-left">
              <h3 className="text-2xl font-bold text-gradient mb-2">LunarAI Beauty</h3>
              <p className="text-sm text-brand-primary">Business Analysis Platform</p>
            </div>
            <div className="text-center text-sm text-brand-primary">
              <p className="font-medium">© 2024 LunarAI Beauty. All rights reserved.</p>
              <p className="mt-2 text-xs">Powered by <span className="font-semibold text-blue-500">Amaizing</span></p>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
