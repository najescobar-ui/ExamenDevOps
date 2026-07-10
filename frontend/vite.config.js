import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react-swc'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    server: {
      // Local dev proxy: each backend keeps its full /api/v1/... path (no rewrite).
      // Targets are overridable via env so they can point at the docker-compose
      // service names when running the frontend outside its container.
      proxy: {
        '/api/v1/ventas': {
          target: env.VITE_VENTAS_TARGET || 'http://localhost:8080',
          changeOrigin: true,
        },
        '/api/v1/despachos': {
          target: env.VITE_DESPACHOS_TARGET || 'http://localhost:8081',
          changeOrigin: true,
        },
      },
    },
  }
})
