import axios from "axios";

// Single API base URL. In production the frontend is served behind the same ALB
// as the backends, so this defaults to an empty string (same-origin) and every
// request uses relative paths like /api/v1/ventas. The ALB routes each path to
// its ECS service. For local dev, Vite proxies these paths (see vite.config.js).
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? "",
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

export default api;
