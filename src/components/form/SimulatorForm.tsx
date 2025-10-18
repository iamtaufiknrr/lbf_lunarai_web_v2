'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useRouter } from 'next/navigation'
import { Loader2, Droplets, Package, Sparkles, User, Users, MapPin, Beaker, Settings, Lightbulb, Heart, Palette, Pipette, Container, Cylinder, Box, CircleDot, Boxes } from 'lucide-react'
import { useSimulator } from '@/contexts/SimulatorContext'
import { buildSubmissionPayload, type FormValues } from '@/lib/payloadBuilder'
import { useToast } from '@/hooks/use-toast'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Switch } from '@/components/ui/switch'
import { Slider } from '@/components/ui/slider'
import { Checkbox } from '@/components/ui/checkbox'
import { IconSelector } from './IconSelector'
import { SelectWithOther } from './SelectWithOther'
import { TagIngredientsInput } from './TagIngredientsInput'
import { FunctionSelector } from './FunctionSelector'
import { GlowButton } from '@/components/common/GlowButton'
import { formatCurrency, generateQuarters } from '@/lib/utils'
import { getIndonesiaProvinces, getCitiesByProvince } from '@/lib/indonesiaLocations'

const formSchema = z.object({
  brandName: z.string().min(1, 'Nama brand wajib diisi'),
  brandVoice: z.string().min(1, 'Voice brand wajib dipilih'),
  brandValues: z.string().min(1, 'Nilai brand wajib diisi'),
  functions: z.array(z.string()).min(1, 'Pilih minimal 1 fungsi'),
  formType: z.string().min(1, 'Tipe produk wajib dipilih'),
  packagingType: z.string().min(1, 'Jenis kemasan wajib dipilih'),
  packagingFinish: z.string().optional(),
  packagingMaterialNotes: z.string().optional(),
  nettoValue: z.number().positive('Netto harus lebih dari 0'),
  nettoUnit: z.enum(['ml', 'g']),
  colorDescription: z.string().min(1, 'Deskripsi warna wajib diisi'),
  colorHex: z.string().optional(),
  gender: z.string().min(1, 'Target gender wajib dipilih'),
  ageRanges: z.array(z.string()).min(1, 'Pilih minimal 1 rentang usia'),
  country: z.string().default('ID'),
  region: z.string().min(1, 'Provinsi wajib dipilih'),
  city: z.string().min(1, 'Kota wajib dipilih'),
  formulaNarrative: z.string().min(10, 'Deskripsi konsep minimal 10 karakter'),
  benchmark: z.string().optional(),
  additionalNotes: z.string().optional(),
  ingredients: z.array(z.object({
    name: z.string(),
    inciName: z.string().optional(),
    percentage: z.number().optional(),
    purpose: z.string().optional(),
    notes: z.string().optional(),
  })),
  launchTimeline: z.string().optional(),
  targetRetailPrice: z.number().optional(),
  pilotBatchSize: z.number().optional(),
  moqExpectation: z.number().optional(),
  distributionFocus: z.enum(['Domestic Retail', 'ASEAN Export', 'Global Prestige', 'D2C Online']),
  sustainabilityPriority: z.number().min(0).max(100),
  regulatoryPriority: z.array(z.string()),
  texturePreference: z.string().optional(),
  fragranceProfile: z.string().optional(),
  claimEmphasis: z.array(z.string()).optional(),
  aiImageStyle: z.string().optional(),
  requiresClinicalStudy: z.boolean(),
  needsHalalCertification: z.boolean(),
  preferredChannels: z.array(z.string()).min(1, 'Pilih minimal 1 channel'),
  requestedDeliverables: z.array(z.string()).min(1, 'Pilih minimal 1 deliverable'),
  notesForDesignTeam: z.string().optional(),
})

export function SimulatorForm() {
  const router = useRouter()
  const { toast } = useToast()
  const { environment, incrementSubmissionCount, updateFormValues } = useSimulator()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [selectedProvince, setSelectedProvince] = useState('')

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      country: 'ID',
      functions: [],
      formType: '',
      nettoUnit: 'ml',
      ageRanges: [],
      ingredients: [],
      distributionFocus: 'Domestic Retail',
      sustainabilityPriority: 50,
      regulatoryPriority: [],
      requiresClinicalStudy: false,
      needsHalalCertification: false,
      preferredChannels: [],
      requestedDeliverables: [],
      claimEmphasis: [],
    },
  })

  const provinces = getIndonesiaProvinces()
  const cities = selectedProvince ? getCitiesByProvince(selectedProvince) : []

  // Sync form values to context for LiveBrief preview
  useEffect(() => {
    const subscription = form.watch((values) => {
      updateFormValues(values as Partial<FormValues>)
    })
    return () => subscription.unsubscribe()
  }, [form, updateFormValues])

  const onSubmit = async (values: FormValues) => {
    setIsSubmitting(true)
    try {
      const payload = buildSubmissionPayload({ ...values, targetEnvironment: environment })
      
      const response = await fetch('/api/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        let errorMessage = 'Submission failed'
        try {
          const error = await response.json()
          errorMessage = error.message || errorMessage
        } catch {
          // If response is not JSON, use status text
          errorMessage = `Server error: ${response.statusText}`
        }
        throw new Error(errorMessage)
      }

      // Check if response is JSON
      const contentType = response.headers.get('content-type')
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Server returned invalid response format')
      }

      const result = await response.json()
      incrementSubmissionCount()
      
      // Show different message for mock mode
      if (result.mockMode) {
        toast({
          title: '✅ Form Submitted (Demo Mode)',
          description: result.message || 'Data tersimpan di console. Backend belum dikonfigurasi.',
        })
        // Don't redirect in mock mode, just show success
        console.log('📋 Submission Data:', payload)
      } else {
        toast({
          title: '✅ Berhasil!',
          description: 'Brief produk Anda sedang diproses oleh AI',
        })
        router.push(`/result/${result.submissionId}`)
      }
    } catch (error) {
      toast({
        title: '❌ Gagal',
        description: error instanceof Error ? error.message : 'Terjadi kesalahan',
        variant: 'destructive',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="simulator-form space-y-6">
      {/* Brand Identity Section */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 space-y-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Sparkles className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Identitas Brand</h3>
            <p className="text-sm text-gray-500">Informasi dasar tentang brand Anda</p>
          </div>
        </div>
        
        {/* //_new_nama brand */}
        <div className="space-y-2">
          <Label htmlFor="brandName" className="text-sm font-medium text-gray-700">
            Nama Brand *
          </Label>
          <Input
            id="brandName"
            {...form.register('brandName')}
            placeholder="Contoh: Glowing Skin Co."
            className="input-field bg-white"
          />
          {form.formState.errors.brandName && (
            <p className="text-sm text-red-500">{form.formState.errors.brandName.message}</p>
          )}
        </div>

        <SelectWithOther
          label="Voice Brand *"
          value={form.watch('brandVoice') || ''}
          onChange={(value) => form.setValue('brandVoice', value)}
          options={[
            { value: 'professional', label: 'Profesional & Klinis' },
            { value: 'friendly', label: 'Ramah & Mudah Didekati' },
            { value: 'luxury', label: 'Mewah & Eksklusif' },
            { value: 'playful', label: 'Fun & Energik' },
            { value: 'natural', label: 'Natural & Organik' },
          ]}
          placeholder="Pilih voice brand..."
          error={form.formState.errors.brandVoice?.message}
          helperText="Tone komunikasi brand Anda dengan customer"
        />

        <div className="space-y-2">
          <Label htmlFor="brandValues" className="text-sm font-medium text-gray-700">
            Nilai & Misi Brand *
          </Label>
          <Textarea
            id="brandValues"
            {...form.register('brandValues')}
            placeholder="Contoh: Kami percaya pada kecantikan alami dengan bahan-bahan berkualitas tinggi yang aman dan efektif"
            className="input-field bg-white min-h-[100px]"
          />
          <p className="text-xs text-gray-500">Ceritakan nilai inti dan misi brand Anda</p>
          {form.formState.errors.brandValues && (
            <p className="text-sm text-red-500">{form.formState.errors.brandValues.message}</p>
          )}
        </div>
      </div>

      {/* Product Blueprint Section */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 space-y-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-cyan-100 rounded-lg">
            <Package className="h-5 w-5 text-cyan-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Blueprint Produk</h3>
            <p className="text-sm text-gray-500">Spesifikasi detail produk kosmetik Anda</p>
          </div>
        </div>

        {/* // Select form type */}
        <IconSelector
          label="Tipe Produk *"
          value={form.watch('formType') || ''}
          onChange={(value) => form.setValue('formType', value as string)}
          options={[
            { value: 'Serum', label: 'Serum', icon: Droplets },
            { value: 'Cream', label: 'Krim', icon: Heart },
            { value: 'Gel', label: 'Gel', icon: Beaker },
            { value: 'Lotion', label: 'Lotion', icon: Package },
            { value: 'Stick', label: 'Stick', icon: Lightbulb },
            { value: 'Foam', label: 'Busa', icon: Sparkles },
            { value: 'Essence', label: 'Essence', icon: Droplets },
            { value: 'Mist', label: 'Mist', icon: Sparkles },
          ]}
          error={form.formState.errors.formType?.message}
          horizontal
        />

        {/* // Fill product function */}
        <FunctionSelector
          value={form.watch('functions') || []}
          onChange={(value) => form.setValue('functions', value)}
          error={form.formState.errors.functions?.message}
        />

        {/* //_new_packaging primer */}
        <IconSelector
          label="Jenis Kemasan *"
          value={form.watch('packagingType') || ''}
          onChange={(value) => form.setValue('packagingType', value as string)}
          options={[
            { value: 'airless-pump', label: 'Airless Pump', icon: Cylinder },
            { value: 'dropper', label: 'Dropper', icon: Pipette },
            { value: 'jar', label: 'Jar', icon: Container },
            { value: 'tube', label: 'Tube', icon: Cylinder },
            { value: 'spray', label: 'Spray', icon: Droplets },
            { value: 'stick', label: 'Stick', icon: CircleDot },
            { value: 'bottle', label: 'Bottle', icon: Package },
            { value: 'sachet', label: 'Sachet', icon: Box },
            { value: 'pump-bottle', label: 'Pump Bottle', icon: Boxes },
          ]}
          error={form.formState.errors.packagingType?.message}
          horizontal
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <SelectWithOther
            label="Finishing Kemasan"
            value={form.watch('packagingFinish') || ''}
            onChange={(value) => form.setValue('packagingFinish', value)}
            options={[
              { value: 'matte', label: 'Matte (tidak mengkilap)' },
              { value: 'glossy', label: 'Glossy (mengkilap)' },
              { value: 'frosted', label: 'Frosted (buram)' },
              { value: 'metallic', label: 'Metallic (metalik)' },
            ]}
            placeholder="Pilih finishing..."
            otherPlaceholder="Ketik finishing lainnya..."
          />
          
          <div className="space-y-2">
            <Label htmlFor="packagingMaterialNotes" className="text-sm font-medium text-gray-700">
              Catatan Material
            </Label>
            <Input
              id="packagingMaterialNotes"
              {...form.register('packagingMaterialNotes')}
              placeholder="Contoh: PCR plastic, Glass"
              className="input-field bg-white border-2"
            />
          </div>
        </div>

        {/* //_new_netto */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="nettoValue" className="text-sm font-medium text-gray-700">
              Netto *
            </Label>
            <Input
              id="nettoValue"
              type="number"
              {...form.register('nettoValue', { valueAsNumber: true })}
              placeholder="30"
              className="input-field bg-white border-2"
            />
            {form.formState.errors.nettoValue && (
              <p className="text-sm text-red-500">{form.formState.errors.nettoValue.message}</p>
            )}
          </div>
          <div className="space-y-2">
            <Label htmlFor="nettoUnit" className="text-sm font-medium text-gray-700">
              Satuan *
            </Label>
            <Select
              value={form.watch('nettoUnit') || 'ml'}
              onValueChange={(value) => form.setValue('nettoUnit', value as 'ml' | 'g')}
            >
              <SelectTrigger className="input-field bg-white border-2">
                <SelectValue placeholder="Pilih satuan..." />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ml">ml (mililiter)</SelectItem>
                <SelectItem value="g">g (gram)</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* //_new_warna */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="colorDescription" className="text-sm font-medium text-gray-700">
              Profil Warna *
            </Label>
            <Input
              id="colorDescription"
              {...form.register('colorDescription')}
              placeholder="Contoh: Putih mutiara, Gel transparan"
              className="input-field bg-white border-2"
            />
            {form.formState.errors.colorDescription && (
              <p className="text-sm text-red-500">{form.formState.errors.colorDescription.message}</p>
            )}
          </div>
          <div className="space-y-2">
            <Label htmlFor="colorHex" className="text-sm font-medium text-gray-700">
              Kode Warna (opsional)
            </Label>
            <div className="flex gap-2">
              <Input
                id="colorHex"
                {...form.register('colorHex')}
                placeholder="#FFFFFF"
                className="input-field"
              />
              <input
                type="color"
                value={form.watch('colorHex') || '#FFFFFF'}
                onChange={(e) => form.setValue('colorHex', e.target.value)}
                className="h-10 w-20 rounded-md border cursor-pointer"
              />
            </div>
          </div>
        </div>

        {/* // Select gender */}
        <IconSelector
          label="Target Gender *"
          value={form.watch('gender') || ''}
          onChange={(value) => form.setValue('gender', value as string)}
          options={[
            { value: 'all', label: 'Semua Gender', icon: Users },
            { value: 'female', label: 'Wanita', icon: User },
            { value: 'male', label: 'Pria', icon: User },
            { value: 'non-binary', label: 'Non-Binary', icon: Users },
          ]}
          error={form.formState.errors.gender?.message}
          columns={4}
        />

        {/* // Select age range */}
        <IconSelector
          label="Rentang Usia *"
          value={form.watch('ageRanges') || []}
          onChange={(value) => form.setValue('ageRanges', value as string[])}
          options={[
            { value: 'Infant', label: 'Bayi (0-2 thn)' },
            { value: 'Child', label: 'Anak (3-12 thn)' },
            { value: 'Teen', label: 'Remaja (13-17 thn)' },
            { value: '18-25', label: '18-25 tahun' },
            { value: '26-35', label: '26-35 tahun' },
            { value: '36-50', label: '36-50 tahun' },
            { value: '50+', label: '50+ tahun' },
            { value: 'All Age', label: 'Semua Usia' },
          ]}
          multiple
          error={form.formState.errors.ageRanges?.message}
          columns={4}
        />

        {/* // Fill country > region provinsi > kota */}
        <div className="space-y-4 p-4 bg-blue-50 rounded-xl border border-blue-200">
          <div className="flex items-center gap-2 text-sm font-medium text-blue-900">
            <MapPin className="h-4 w-4" />
            Target Pasar Geografis *
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <SelectWithOther
              label="Provinsi *"
              value={form.watch('region') || ''}
              onChange={(value) => {
                form.setValue('region', value)
                setSelectedProvince(value)
                form.setValue('city', '')
              }}
              options={provinces.map((p) => ({ value: p.code, label: p.name }))}
              placeholder="Pilih provinsi..."
              error={form.formState.errors.region?.message}
            />
            
            <SelectWithOther
              label="Kota *"
              value={form.watch('city') || ''}
              onChange={(value) => form.setValue('city', value)}
              options={cities.map((c) => ({ value: c.code, label: c.name }))}
              placeholder={selectedProvince ? 'Pilih kota...' : 'Pilih provinsi dulu'}
              error={form.formState.errors.city?.message}
              hideOther
            />
          </div>
          <p className="text-xs text-blue-700">
            💡 Data lokasi lengkap 34 provinsi Indonesia.
          </p>
        </div>
      </div>

      {/* Concept & Formula Section */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 space-y-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-purple-100 rounded-lg">
            <Beaker className="h-5 w-5 text-purple-600" />
          </div>
          <div className="flex-1">
            <h3 className="text-lg font-semibold text-gray-900">Konsep & Formula</h3>
            <p className="text-sm text-gray-500">Deskripsikan produk Anda, AI akan membantu</p>
          </div>
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="border-purple-300 text-purple-700 hover:bg-purple-50"
            onClick={() => {
              // TODO: Implement AI generation based on previous form data
              alert('Fitur AI Generate akan mengisi deskripsi berdasarkan data form yang sudah diisi')
            }}
          >
            <Sparkles className="h-4 w-4 mr-2" />
            Generate dengan AI
          </Button>
        </div>

        {/* // Fill concept formula */}
        <div className="space-y-2">
          <Label htmlFor="formulaNarrative" className="text-sm font-medium text-gray-700">
            Deskripsi Konsep Produk *
          </Label>
          <Textarea
            id="formulaNarrative"
            {...form.register('formulaNarrative')}
            placeholder="Contoh: Serum brightening dengan niacinamide 10% untuk mencerahkan dan meratakan warna kulit. Cocok untuk kulit kusam dan bekas jerawat. Tekstur ringan, cepat menyerap."
            className="input-field bg-white min-h-[120px]"
          />
          <p className="text-xs text-gray-500">
            💡 Jelaskan manfaat utama, masalah yang diatasi, dan tekstur yang diinginkan
          </p>
          {form.formState.errors.formulaNarrative && (
            <p className="text-sm text-red-500">{form.formState.errors.formulaNarrative.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="benchmark" className="text-sm font-medium text-gray-700">
            Produk Referensi (opsional)
          </Label>
          <Input
            id="benchmark"
            {...form.register('benchmark')}
            placeholder="Contoh: The Ordinary Niacinamide 10%"
            className="input-field bg-white"
          />
          <p className="text-xs text-gray-500">Produk existing yang menjadi inspirasi atau benchmark</p>
        </div>

        {/* // Add ingredients */}
        <TagIngredientsInput
          value={form.watch('ingredients') || []}
          onChange={(value) => form.setValue('ingredients', value)}
        />

        <div className="space-y-2">
          <Label htmlFor="additionalNotes" className="text-sm font-medium text-gray-700">
            Catatan Tambahan
          </Label>
          <Textarea
            id="additionalNotes"
            {...form.register('additionalNotes')}
            placeholder="Batasan, preferensi, atau informasi penting lainnya"
            className="input-field bg-white"
          />
        </div>
      </div>

      {/* Extended Product Details */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 space-y-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-green-100 rounded-lg">
            <Settings className="h-5 w-5 text-green-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Detail Produksi & Regulasi</h3>
            <p className="text-sm text-gray-500">Informasi manufacturing dan compliance</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* //_new_requires clinical study */}
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-200">
            <div>
              <Label htmlFor="requiresClinicalStudy" className="text-sm font-medium text-gray-700">
                Perlu Uji Klinis?
              </Label>
              <p className="text-xs text-gray-500 mt-1">Testing efektivitas produk</p>
            </div>
            <Switch
              id="requiresClinicalStudy"
              checked={form.watch('requiresClinicalStudy')}
              onCheckedChange={(checked) => form.setValue('requiresClinicalStudy', checked)}
            />
          </div>

          {/* //_new_needs halal certification */}
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-200">
            <div>
              <Label htmlFor="needsHalalCertification" className="text-sm font-medium text-gray-700">
                Perlu Sertifikasi Halal?
              </Label>
              <p className="text-xs text-gray-500 mt-1">Untuk pasar Muslim</p>
            </div>
            <Switch
              id="needsHalalCertification"
              checked={form.watch('needsHalalCertification')}
              onCheckedChange={(checked) => form.setValue('needsHalalCertification', checked)}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* //_new_preferred launch timeline */}
          <div className="space-y-2">
            <Label className="text-sm font-medium text-gray-700">Timeline Peluncuran</Label>
            <div className="grid grid-cols-2 gap-3">
              <Select
                value={form.watch('launchTimeline') || ''}
                onValueChange={(value) => form.setValue('launchTimeline', value)}
              >
                <SelectTrigger className="input-field bg-white border-2">
                  <SelectValue placeholder="Pilih quarter..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Q1">Quarter 1</SelectItem>
                  <SelectItem value="Q2">Quarter 2</SelectItem>
                  <SelectItem value="Q3">Quarter 3</SelectItem>
                  <SelectItem value="Q4">Quarter 4</SelectItem>
                </SelectContent>
              </Select>
              <Select
                value={form.watch('launchYear') || new Date().getFullYear().toString()}
                onValueChange={(value) => form.setValue('launchYear', value)}
              >
                <SelectTrigger className="input-field bg-white border-2">
                  <SelectValue placeholder="Tahun..." />
                </SelectTrigger>
                <SelectContent>
                  {[2024, 2025, 2026, 2027, 2028].map((year) => (
                    <SelectItem key={year} value={year.toString()}>
                      {year}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* //_new_target retail price */}
          <div className="space-y-2">
            <Label htmlFor="targetRetailPrice" className="text-sm font-medium text-gray-700">
              Target Harga Retail (IDR)
            </Label>
            <Input
              id="targetRetailPrice"
              type="number"
              {...form.register('targetRetailPrice', { valueAsNumber: true })}
              placeholder="150000"
              className="input-field bg-white border-2"
            />
            {form.watch('targetRetailPrice') && !isNaN(form.watch('targetRetailPrice')) && form.watch('targetRetailPrice') > 0 && (
              <p className="text-xs text-blue-600 font-medium">
                {formatCurrency(form.watch('targetRetailPrice'))}
              </p>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* //_new_pilot batch size */}
          <div className="space-y-2">
            <Label htmlFor="pilotBatchSize" className="text-sm font-medium text-gray-700">
              Pilot Batch (unit)
            </Label>
            <Input
              id="pilotBatchSize"
              type="number"
              {...form.register('pilotBatchSize', { valueAsNumber: true })}
              placeholder="500"
              className="input-field bg-white border-2"
            />
            <p className="text-xs text-gray-500">Produksi awal untuk testing</p>
          </div>

          {/* //_new_moq expectation */}
          <div className="space-y-2">
            <Label htmlFor="moqExpectation" className="text-sm font-medium text-gray-700">
              MOQ (unit)
            </Label>
            <Input
              id="moqExpectation"
              type="number"
              {...form.register('moqExpectation', { valueAsNumber: true })}
              placeholder="1000"
              className="input-field bg-white border-2"
            />
            <p className="text-xs text-gray-500">Minimum order quantity</p>
          </div>

          {/* //_new_distribution focus */}
          <SelectWithOther
            label="Fokus Distribusi *"
            value={form.watch('distributionFocus') || 'Domestic Retail'}
            onChange={(value) => form.setValue('distributionFocus', value as any)}
            options={[
              { value: 'Domestic Retail', label: 'Retail Domestik' },
              { value: 'ASEAN Export', label: 'Ekspor ASEAN' },
              { value: 'Global Prestige', label: 'Global Prestige' },
              { value: 'D2C Online', label: 'D2C Online' },
            ]}
            placeholder="Pilih fokus distribusi..."
          />
        </div>

        {/* //_new_sustainability priority */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <Label className="text-sm font-medium text-gray-700">
              Prioritas Sustainability
            </Label>
            <span className="text-sm font-semibold text-blue-600">
              {form.watch('sustainabilityPriority')}%
            </span>
          </div>
          <Slider
            value={[form.watch('sustainabilityPriority') || 50]}
            onValueChange={(value) => form.setValue('sustainabilityPriority', value[0])}
            max={100}
            step={10}
            className="w-full"
          />
          <div className="flex justify-between text-xs text-gray-500">
            <span>Tidak prioritas</span>
            <span>Sangat prioritas</span>
          </div>
        </div>

        {/* //_new_regulatory priority */}
        <div className="space-y-3">
          <Label className="text-sm font-medium text-gray-700">
            Prioritas Regulasi
          </Label>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {['BPOM Indonesia', 'Halal MUI', 'FDA (US)', 'EU CPNP', 'ASEAN Cosmetic', 'Vegan Society'].map((reg) => (
              <label key={reg} className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100 transition-colors">
                <Checkbox
                  checked={form.watch('regulatoryPriority')?.includes(reg)}
                  onCheckedChange={(checked) => {
                    const current = form.watch('regulatoryPriority') || []
                    form.setValue(
                      'regulatoryPriority',
                      checked ? [...current, reg] : current.filter((r) => r !== reg)
                    )
                  }}
                />
                <span className="text-sm">{reg}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* //_new_texture preference */}
          <div className="space-y-2">
            <Label htmlFor="texturePreference" className="text-sm font-medium text-gray-700">
              Preferensi Tekstur
            </Label>
            <Textarea
              id="texturePreference"
              {...form.register('texturePreference')}
              placeholder="Contoh: Ringan, cepat menyerap, tidak lengket"
              className="input-field bg-white min-h-[80px]"
            />
          </div>

          {/* //_new_fragrance profile */}
          <div className="space-y-2">
            <Label htmlFor="fragranceProfile" className="text-sm font-medium text-gray-700">
              Profil Aroma
            </Label>
            <Textarea
              id="fragranceProfile"
              {...form.register('fragranceProfile')}
              placeholder="Contoh: Floral ringan, atau tanpa pewangi"
              className="input-field bg-white min-h-[80px]"
            />
          </div>
        </div>

        {/* //_new_claim emphasis */}
        <div className="space-y-3">
          <Label className="text-sm font-medium text-gray-700">
            Klaim Produk (opsional)
          </Label>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {['Dermatologically Tested', 'Reef Safe', 'Blue Light Shield', 'Pregnancy Safe', 'Cruelty-Free', 'Vegan'].map((claim) => (
              <label key={claim} className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100 transition-colors">
                <Checkbox
                  checked={form.watch('claimEmphasis')?.includes(claim)}
                  onCheckedChange={(checked) => {
                    const current = form.watch('claimEmphasis') || []
                    form.setValue(
                      'claimEmphasis',
                      checked ? [...current, claim] : current.filter((c) => c !== claim)
                    )
                  }}
                />
                <span className="text-xs">{claim}</span>
              </label>
            ))}
          </div>
        </div>

        {/* //_new_ai image style */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="aiImageStyle" className="text-sm font-medium text-gray-700">
              Gaya Visual AI (opsional)
            </Label>
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="border-purple-300 text-purple-700 hover:bg-purple-50"
              onClick={() => {
                // TODO: Implement AI suggestion based on brand voice and product type
                const suggestions = ['Minimalist modern photography', 'Botanical luxury illustration', 'Clean clinical aesthetic', 'Vibrant tropical vibes']
                const random = suggestions[Math.floor(Math.random() * suggestions.length)]
                form.setValue('aiImageStyle', random)
              }}
            >
              <Sparkles className="h-3 w-3 mr-1" />
              Suggest AI
            </Button>
          </div>
          <Input
            id="aiImageStyle"
            {...form.register('aiImageStyle')}
            placeholder="Contoh: Minimalist product photography, Botanical illustration"
            className="input-field bg-white"
          />
          <p className="text-xs text-gray-500">Deskripsi untuk generasi gambar/packaging AI</p>
        </div>
      </div>

      {/* Collaboration Preferences */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-200 space-y-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-orange-100 rounded-lg">
            <Heart className="h-5 w-5 text-orange-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Preferensi Kolaborasi</h3>
            <p className="text-sm text-gray-500">Channel komunikasi dan deliverables yang diinginkan</p>
          </div>
        </div>

        <div className="space-y-3">
          <Label className="text-sm font-medium text-gray-700">
            Channel Komunikasi *
          </Label>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {['Email', 'WhatsApp', 'Telegram', 'Instagram DM', 'Line', 'Google Meet', 'Zoom', 'Phone Call'].map((channel) => (
              <label key={channel} className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100 transition-colors">
                <Checkbox
                  checked={form.watch('preferredChannels')?.includes(channel)}
                  onCheckedChange={(checked) => {
                    const current = form.watch('preferredChannels') || []
                    form.setValue(
                      'preferredChannels',
                      checked ? [...current, channel] : current.filter((c) => c !== channel)
                    )
                  }}
                />
                <span className="text-sm">{channel}</span>
              </label>
            ))}
          </div>
          {form.formState.errors.preferredChannels && (
            <p className="text-sm text-red-500">{form.formState.errors.preferredChannels.message}</p>
          )}
        </div>

        <IconSelector
          label="Deliverables yang Diinginkan *"
          value={form.watch('requestedDeliverables') || []}
          onChange={(value) => form.setValue('requestedDeliverables', value as string[])}
          options={[
            { value: 'AI concept deck', label: 'AI Concept Deck', icon: Lightbulb },
            { value: 'Packaging mockups', label: 'Packaging Mockups', icon: Package },
            { value: 'Campaign prompts', label: 'Campaign Prompts', icon: Sparkles },
            { value: 'Ingredient dossier', label: 'Ingredient Dossier', icon: Beaker },
            { value: 'Regulatory dossier', label: 'Regulatory Dossier', icon: Settings },
            { value: 'Formula development', label: 'Formula Development', icon: Droplets },
            { value: 'Market analysis', label: 'Market Analysis', icon: Users },
            { value: 'Brand guidelines', label: 'Brand Guidelines', icon: Palette },
          ]}
          multiple
          horizontal
          error={form.formState.errors.requestedDeliverables?.message}
        />

        <div className="space-y-2">
          <Label htmlFor="notesForDesignTeam" className="text-sm font-medium text-gray-700">
            Catatan untuk Tim Desain
          </Label>
          <Textarea
            id="notesForDesignTeam"
            {...form.register('notesForDesignTeam')}
            placeholder="Brief kreatif, mood board, referensi, atau informasi tambahan lainnya"
            className="input-field bg-white min-h-[100px]"
          />
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex flex-col md:flex-row gap-4 justify-center items-center">
        <GlowButton type="submit" disabled={isSubmitting} className="px-12 py-4 text-lg font-semibold">
          {isSubmitting ? (
            <>
              <Loader2 className="mr-2 h-5 w-5 animate-spin" />
              Memproses...
            </>
          ) : (
            <>
              Buat Brief Produk
            </>
          )}
        </GlowButton>
        <Button
          type="button"
          variant="outline"
          size="lg"
          className="px-8 py-4 text-lg font-semibold border-2 border-green-500 text-green-700 hover:bg-green-50"
          onClick={() => {
            window.open('https://wa.me/6281234567890?text=Halo,%20saya%20tertarik%20untuk%20konsultasi%20produk%20kosmetik', '_blank')
          }}
        >
          <svg className="mr-2 h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
          </svg>
          Hubungi Kami Sekarang
        </Button>
      </div>
    </form>
  )
}
