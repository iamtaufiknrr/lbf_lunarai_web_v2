# LBF Technoglow Workspace

Workspace ini sudah dipisahkan ke dalam kategori utama supaya mudah memilih artefak untuk deployment, automation, maupun pekerjaan lokal.

## Folder Kategori
- `apps/bolt-vercel/` — source code Next.js 14 yang siap di-upload ke Bolt.new atau Vercel (sudah berisi `package.json`, konfigurasi Next/Tailwind, dan dependensi).
- `automation/n8n/` — workflow, dokumentasi, dan skrip helper yang berkaitan dengan orkestrasi n8n + database.
- `data/` — artefak data mentah (schema SQL, skrip backup, payload uji) yang dipakai oleh n8n dan aplikasi.
- `docs/` — dokumentasi terstruktur (project overview, panduan Bolt/Vercel, catatan n8n, dll).
- `support/local-tools/` — skrip bantu untuk menjalankan/men-setup proyek secara lokal di Windows (install, start, generate env).

Struktur ringkas:

```
apps/
  bolt-vercel/
    package.json
    src/
    tests/
    ...
automation/
  n8n/
    integration/
    scripts/
data/
  n8n/
    database/
    test-payload.json
docs/
  bolt-vercel/
  n8n/
  project-overview/
support/
  local-tools/
```

## Menjalankan Secara Lokal
1. Jalankan `support/local-tools/install.bat` (opsional) atau manual:
   ```powershell
   cd apps/bolt-vercel
   npm install
   ```
2. Buat file environment:
   - `support/local-tools/create-env.ps1` (preset webhook demo), atau
   - `automation/n8n/scripts/setup-env-n8n.ps1` untuk input manual.
3. Start dev server:
   ```powershell
   cd apps/bolt-vercel
   npm run dev
   ```
4. Buka `http://localhost:3004`.

## Deploy ke Bolt.new
1. Kompres folder `apps/bolt-vercel` atau gunakan fitur upload folder langsung.
2. Bolt otomatis membaca `package.json` dan script `npm run build`/`npm run start`.
3. Setelah upload, cek tab Logs — bila environment diperlukan, gunakan `.env.local` yang sama dengan lokal.

## Deploy ke Vercel
1. Buat project baru -> pilih repositori ini.
2. Set **Root Directory** ke `apps/bolt-vercel`.
3. Build Command: `npm run build`; Output Directory: `.next` (default Vercel).
4. Isi environment variables lewat Settings -> Environment Variables (gunakan file `.env.local` yang sama).

## Integrasi n8n
- Dokumentasi lengkap: `automation/n8n/integration/00-START-HERE.md`.
- Workflow, konfigurasi MCP, dan panduan testing berada di subfolder `02-N8N-Workflows`, `05-Testing`, `06-Deployment`, dll.
- Payload contoh sekarang di `data/n8n/test-payload.json`. Ikuti update path yang sudah direvisi pada dokumentasi.

## Artefak Data
- Schema & skrip Postgres: `data/n8n/database/*.sql` dan `backup-restore.sh`.
- Payload uji end-to-end: `data/n8n/test-payload.json`.
- Penjelasan singkat tersedia di `data/README.md`.

## Dokumentasi Penting
- Overview & timeline: `docs/project-overview/` (DOCS-INDEX, PROJECT_SUMMARY, dll).
- Catatan front-end (Bolt/Vercel): `docs/bolt-vercel/`.
- Troubleshooting n8n: `docs/n8n/` (`TROUBLESHOOT-N8N.md`, `QUICK-FIX-N8N.md`, dsb).
- Arsitektur & environment umum: `docs/environment_setup.md`, `docs/system_architecture.md`.

## Script Bantuan
- `support/local-tools/install.bat` — instal dependensi (npm install) dan menyiapkan direktori yang benar.
- `support/local-tools/start.bat` — membuka browser + menjalankan `npm run dev` di folder aplikasi.
- `support/local-tools/create-env.ps1` — generate `.env.local` default di `apps/bolt-vercel`.
- `automation/n8n/scripts/setup-env-n8n.ps1` — builder env interaktif khusus n8n.

## Next Steps Disarankan
- Commit perubahan struktur bila sudah dicek.
- Jalankan `npm run build` dari `apps/bolt-vercel` sebelum upload guna memastikan tidak ada error build.
- Update kredensial environment di Bolt/Vercel setelah deploy.
