'use client'

import { motion } from 'framer-motion'
import { useSimulator } from '@/contexts/SimulatorContext'
import { GlassCard } from '@/components/common/GlassCard'
import { NeonBadge } from '@/components/common/NeonBadge'
import { Package, Target, Calendar, Leaf } from 'lucide-react'

export function LiveBrief() {
  const { formValues } = useSimulator()

  if (!formValues.brandName) {
    return (
      <GlassCard className="h-full">
        <div className="flex items-center justify-center h-full text-center p-8">
          <div>
            <Package className="h-12 w-12 mx-auto mb-4 text-brand-primary opacity-50" />
            <p className="text-brand-primary">
              Start filling the form to see your product brief preview
            </p>
          </div>
        </div>
      </GlassCard>
    )
  }

  return (
    <GlassCard className="h-full overflow-auto">
      <div className="space-y-6">
        <div>
          <h3 className="text-2xl font-bold text-brand-secondary mb-2">
            {formValues.brandName || 'Your Brand'}
          </h3>
          {formValues.formType && (
            <NeonBadge variant="blue">{formValues.formType}</NeonBadge>
          )}
        </div>

        {formValues.functions && formValues.functions.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="flex items-center gap-2 text-sm font-medium text-brand-secondary">
              <Target className="h-4 w-4" />
              Functions
            </div>
            <div className="flex flex-wrap gap-2">
              {formValues.functions.map((func) => (
                <NeonBadge key={func} variant="cyan">
                  {func}
                </NeonBadge>
              ))}
            </div>
          </motion.div>
        )}

        {formValues.packagingType && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="flex items-center gap-2 text-sm font-medium text-brand-secondary">
              <Package className="h-4 w-4" />
              Packaging
            </div>
            <p className="text-sm text-brand-primary">{formValues.packagingType}</p>
            {formValues.nettoValue && (
              <p className="text-sm text-brand-primary">
                {formValues.nettoValue} {formValues.nettoUnit}
              </p>
            )}
          </motion.div>
        )}

        {formValues.launchTimeline && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="flex items-center gap-2 text-sm font-medium text-brand-secondary">
              <Calendar className="h-4 w-4" />
              Launch Timeline
            </div>
            <p className="text-sm text-brand-primary">{formValues.launchTimeline}</p>
          </motion.div>
        )}

        {formValues.sustainabilityPriority !== undefined && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="flex items-center gap-2 text-sm font-medium text-brand-secondary">
              <Leaf className="h-4 w-4" />
              Sustainability Score
            </div>
            <div className="flex items-center gap-3">
              <div className="flex-1 h-2 bg-brand-lightGray rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${formValues.sustainabilityPriority}%` }}
                  className="h-full bg-gradient-to-r from-brand-blue to-brand-cyan"
                />
              </div>
              <span className="text-sm font-medium text-brand-blue">
                {formValues.sustainabilityPriority}
              </span>
            </div>
          </motion.div>
        )}

        {formValues.regulatoryPriority && formValues.regulatoryPriority.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="text-sm font-medium text-brand-secondary">Regulatory Focus</div>
            <div className="flex flex-wrap gap-2">
              {formValues.regulatoryPriority.map((reg) => (
                <NeonBadge key={reg} variant="gray">
                  {reg}
                </NeonBadge>
              ))}
            </div>
          </motion.div>
        )}

        {formValues.claimEmphasis && formValues.claimEmphasis.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2"
          >
            <div className="text-sm font-medium text-brand-secondary">Claims</div>
            <div className="flex flex-wrap gap-2">
              {formValues.claimEmphasis.map((claim) => (
                <NeonBadge key={claim} variant="cyan">
                  {claim}
                </NeonBadge>
              ))}
            </div>
          </motion.div>
        )}
      </div>
    </GlassCard>
  )
}
