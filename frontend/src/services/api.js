const BASE_URL = "https://6odxcq4waj.execute-api.us-east-1.amazonaws.com/api";

export async function fetchDashboard() {
  const res = await fetch(`${BASE_URL}/dashboard`);
  if (!res.ok) throw new Error("Failed to fetch dashboard data");
  const data = await res.json();
  return data.accounts || data;
}

export async function fetchAccountTranscripts(accountId) {
  const res = await fetch(`${BASE_URL}/account/${accountId}/transcripts`);
  if (!res.ok) throw new Error("Failed to fetch transcripts");
  return res.json();
}

export async function queryRAG(query) {
  const res = await fetch(`${BASE_URL}/rag`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query }),
  });
  if (!res.ok) throw new Error("Failed to query RAG");
  return res.json();
}