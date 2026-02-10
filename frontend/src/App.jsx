import { useState, useEffect } from "react";

const API = "https://6odxcq4waj.execute-api.us-east-1.amazonaws.com/api";

function getRisk(a) {
  if (a.IS_CHURNED) return "churned";
  if (a.HEALTH_SCORE >= 65) return "healthy";
  if (a.HEALTH_SCORE >= 40) return "at_risk";
  return "critical";
}

const tierBadge = {
  healthy: "bg-emerald-900/40 text-emerald-400 border border-emerald-700/50",
  at_risk: "bg-yellow-900/40 text-yellow-400 border border-yellow-700/50",
  critical: "bg-red-900/40 text-red-400 border border-red-700/50",
  churned: "bg-gray-800 text-gray-500 border border-gray-700",
};
const tierLabel = { healthy: "Healthy", at_risk: "At Risk", critical: "Critical", churned: "Churned" };

function ExpandedRow({ account }) {
  const [transcripts, setTranscripts] = useState([]);
  const [loadingTx, setLoadingTx] = useState(true);
  const [recommendation, setRecommendation] = useState(null);
  const [loadingRec, setLoadingRec] = useState(true);
  const [txSummary, setTxSummary] = useState(null);
  const [loadingTxSum, setLoadingTxSum] = useState(true);

  useEffect(() => {
    // Fetch transcripts, then summarize them
    fetch(`${API}/account/${account.ACCOUNT_ID}/transcripts`)
      .then((r) => r.json())
      .then((data) => {
        const list = Array.isArray(data) ? data : data.transcripts || [];
        setTranscripts(list);
        setLoadingTx(false);

        // Summarize transcripts if we have any with body text
        const bodies = list.filter((t) => t.TRANSCRIPT_BODY).map((t) => `[${t.INTERACTION_TYPE} | ${t.TIMESTAMP || "unknown date"} | Sentiment: ${t.SENTIMENT_SCORE}]\n${t.TRANSCRIPT_BODY}`);
        if (bodies.length > 0) {
          fetch(`${API}/rag`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              query: `Summarize the following customer interaction transcripts for account ${account.ACCOUNT_ID} (${account.INDUSTRY}, ${account.TIER} tier). Highlight the key themes, recurring issues, tone shifts over time, and overall customer experience trajectory. Keep it to 3-4 sentences. Be specific about what the customer complained about or discussed.\n\nTRANSCRIPTS:\n${bodies.join("\n\n")}`
            }),
          })
            .then((r) => r.json())
            .then((data) => { setTxSummary(data.answer || "Unable to summarize."); setLoadingTxSum(false); })
            .catch(() => { setTxSummary("Unable to summarize."); setLoadingTxSum(false); });
        } else {
          setTxSummary(null);
          setLoadingTxSum(false);
        }
      })
      .catch(() => { setLoadingTx(false); setLoadingTxSum(false); });

    // Account recommendation
    fetch(`${API}/rag`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        query: `Give a brief, actionable recommendation for account ${account.ACCOUNT_ID}. This is a ${account.TIER} tier ${account.INDUSTRY} account with a health score of ${account.HEALTH_SCORE}, sentiment of ${account.AVG_SENTIMENT}, ${account.SUPPORT_TICKET_COUNT} support tickets, ${account.DAYS_SINCE_LAST_ACTIVE} days inactive, and top complaint category: ${account.TOP_COMPLAINT_CATEGORY || "none"}. ${account.IS_CHURNED ? "This account has already churned." : ""} What specific steps should the customer success team take? Keep it to 2-3 sentences.`
      }),
    })
      .then((r) => r.json())
      .then((data) => { setRecommendation(data.answer || "Unable to generate recommendation."); setLoadingRec(false); })
      .catch(() => { setRecommendation("Unable to generate recommendation."); setLoadingRec(false); });
  }, [account.ACCOUNT_ID]);

  const risk = getRisk(account);

  return (
    <tr>
      <td colSpan={8} className="p-0">
        <div className="bg-gray-900/50 border-t border-b border-gray-700 px-6 py-5">
          {/* Header */}
          <div className="flex flex-wrap items-center justify-between gap-4 mb-5">
            <div>
              <span className="text-lg font-bold text-white">{account.ACCOUNT_ID}</span>
              <span className="text-sm text-gray-400 ml-3">{account.INDUSTRY} · {account.TIER} tier</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-right">
                <p className="text-3xl font-bold text-white">{account.HEALTH_SCORE}</p>
                <p className="text-xs text-gray-500">Health Score</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-semibold ${tierBadge[risk]}`}>{tierLabel[risk]}</span>
            </div>
          </div>

          {/* Signals */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-5">
            {[
              ["Sessions", account.TOTAL_SESSIONS],
              ["Features", account.FEATURES_ADOPTED != null ? `${account.FEATURES_ADOPTED}/12` : null],
              ["Error Rate", account.ERROR_RATE != null ? `${(account.ERROR_RATE * 100).toFixed(1)}%` : null],
              ["Avg Duration", account.AVG_SESSION_DURATION != null ? `${account.AVG_SESSION_DURATION.toFixed(0)} min` : null],
              ["Days Inactive", account.DAYS_SINCE_LAST_ACTIVE],
              ["Sentiment", account.AVG_SENTIMENT != null ? account.AVG_SENTIMENT.toFixed(2) : null],
              ["Tickets", account.SUPPORT_TICKET_COUNT],
              ["Top Complaint", account.TOP_COMPLAINT_CATEGORY || "None"],
            ].map(([label, value]) => (
              <div key={label} className="bg-gray-800/80 rounded-lg border border-gray-700 p-3">
                <p className="text-xs text-gray-500 uppercase tracking-wide">{label}</p>
                <p className="text-lg font-bold text-white mt-1">{value ?? "—"}</p>
              </div>
            ))}
          </div>

          {/* AI Recommendation */}
          <div className="mb-5 bg-blue-950/40 border border-blue-800/50 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <span className="text-sm font-semibold text-blue-400">✦ AI-Assisted Recommendation</span>
            </div>
            {loadingRec ? (
              <p className="text-gray-500 text-sm italic">Generating recommendation...</p>
            ) : (
              <p className="text-gray-200 text-sm leading-relaxed">{recommendation}</p>
            )}
            <p className="text-xs text-gray-600 mt-3 italic">
              ⚠ AI-generated content may be inaccurate. Always cross-reference with the metrics above as the source of truth before making decisions.
            </p>
          </div>

          {/* Transcripts */}
          <p className="font-semibold text-sm text-gray-300 mb-2 uppercase tracking-wide">Interaction Transcripts</p>

          {/* Transcript Summary */}
          {!loadingTxSum && txSummary && (
            <div className="mb-4 bg-purple-950/30 border border-purple-800/40 rounded-xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-sm font-semibold text-purple-400">✦ AI Transcript Summary</span>
              </div>
              <p className="text-gray-200 text-sm leading-relaxed">{txSummary}</p>
              <p className="text-xs text-gray-600 mt-3 italic">
                ⚠ AI-generated summary. Refer to the individual transcripts below for exact details.
              </p>
            </div>
          )}
          {loadingTxSum && transcripts.length > 0 && (
            <div className="mb-4 bg-purple-950/30 border border-purple-800/40 rounded-xl p-4">
              <p className="text-gray-500 text-sm italic">Summarizing transcripts...</p>
            </div>
          )}

          {loadingTx ? <p className="text-gray-500 text-sm">Loading...</p>
          : transcripts.length === 0 ? <p className="text-gray-600 text-sm">No transcripts found.</p>
          : (
            <div className="rounded-lg border border-gray-700 overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-gray-800 text-gray-400">
                  <tr>
                    <th className="px-3 py-2 text-left text-xs uppercase tracking-wide">ID</th>
                    <th className="px-3 py-2 text-left text-xs uppercase tracking-wide">Type</th>
                    <th className="px-3 py-2 text-left text-xs uppercase tracking-wide">Date</th>
                    <th className="px-3 py-2 text-left text-xs uppercase tracking-wide">Sentiment</th>
                    <th className="px-3 py-2 text-left text-xs uppercase tracking-wide">Complaint</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700/50">
                  {transcripts.map((t) => (
                    <tr key={t.INTERACTION_ID} className="hover:bg-gray-800/50">
                      <td className="px-3 py-2 text-gray-300">{t.INTERACTION_ID}</td>
                      <td className="px-3 py-2 text-gray-300 capitalize">{t.INTERACTION_TYPE}</td>
                      <td className="px-3 py-2 text-gray-400">{t.TIMESTAMP || "—"}</td>
                      <td className={`px-3 py-2 font-medium ${(t.SENTIMENT_SCORE ?? 0) >= 0 ? "text-emerald-400" : "text-red-400"}`}>
                        {t.SENTIMENT_SCORE != null ? t.SENTIMENT_SCORE.toFixed(2) : "—"}
                      </td>
                      <td className="px-3 py-2 text-gray-300">{t.COMPLAINT_CATEGORY || "—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </td>
    </tr>
  );
}

function App() {
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [sortCol, setSortCol] = useState("HEALTH_SCORE");
  const [sortAsc, setSortAsc] = useState(true);
  const [search, setSearch] = useState("");
  const [filterRisk, setFilterRisk] = useState("all");
  const [filterIndustry, setFilterIndustry] = useState("all");
  const [expanded, setExpanded] = useState(null);

  useEffect(() => {
    fetch(`${API}/dashboard`)
      .then((r) => r.json())
      .then((data) => { setAccounts(Array.isArray(data) ? data : data.accounts || []); setLoading(false); })
      .catch((err) => { setError(err.message); setLoading(false); });
  }, []);

  if (loading) return <div className="min-h-screen bg-gray-950 flex items-center justify-center"><p className="text-gray-500 text-lg">Loading dashboard...</p></div>;
  if (error) return <div className="min-h-screen bg-gray-950 flex items-center justify-center"><p className="text-red-400 text-lg">Error: {error}</p></div>;

  const industries = [...new Set(accounts.map((a) => a.INDUSTRY))].sort();

  const filtered = accounts.filter((a) => {
    if (filterRisk !== "all" && getRisk(a) !== filterRisk) return false;
    if (filterIndustry !== "all" && a.INDUSTRY !== filterIndustry) return false;
    if (search && !a.ACCOUNT_ID.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const handleSort = (col) => {
    if (sortCol === col) setSortAsc(!sortAsc);
    else { setSortCol(col); setSortAsc(true); }
  };

  const sorted = [...filtered].sort((a, b) => {
    let valA = a[sortCol], valB = b[sortCol];
    if (valA == null) return 1;
    if (valB == null) return -1;
    if (typeof valA === "string") return sortAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
    return sortAsc ? valA - valB : valB - valA;
  });

  const healthy = accounts.filter((a) => getRisk(a) === "healthy").length;
  const atRisk = accounts.filter((a) => getRisk(a) === "at_risk").length;
  const critical = accounts.filter((a) => getRisk(a) === "critical").length;
  const churned = accounts.filter((a) => getRisk(a) === "churned").length;

  const cards = [
    { label: "Total Accounts", value: accounts.length, style: "from-blue-600/20 to-blue-900/20 border-blue-700/40 text-blue-400" },
    { label: "Healthy", value: healthy, style: "from-emerald-600/20 to-emerald-900/20 border-emerald-700/40 text-emerald-400" },
    { label: "At Risk", value: atRisk, style: "from-yellow-600/20 to-yellow-900/20 border-yellow-700/40 text-yellow-400" },
    { label: "Critical", value: critical, style: "from-red-600/20 to-red-900/20 border-red-700/40 text-red-400" },
    { label: "Churned", value: churned, style: "from-gray-600/20 to-gray-800/20 border-gray-700/40 text-gray-500" },
  ];

  return (
    <div className="min-h-screen bg-gray-950 text-gray-200">
      <header className="border-b border-gray-800 px-6 py-10">
        <div className="max-w-7xl mx-auto text-center">
          <h1 className="text-3xl font-extrabold text-white tracking-tight">VantagePoint Customer Intelligence Platform</h1>
          <p className="text-sm text-gray-400 mt-3 italic">From data silos to decisive action — know your customers before they leave.</p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          {cards.map((c) => (
            <div key={c.label} className={`rounded-xl bg-gradient-to-br border p-5 ${c.style}`}>
              <p className="text-xs font-medium uppercase tracking-wide opacity-70">{c.label}</p>
              <p className="text-3xl font-bold text-white mt-2">{c.value}</p>
            </div>
          ))}
        </div>

        <div className="mt-8 flex flex-wrap gap-3 items-center">
          <input type="text" placeholder="Search Account ID..." value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
          <select value={filterRisk} onChange={(e) => setFilterRisk(e.target.value)}
            className="px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200">
            <option value="all">All Risk Tiers</option>
            <option value="healthy">Healthy</option>
            <option value="at_risk">At Risk</option>
            <option value="critical">Critical</option>
            <option value="churned">Churned</option>
          </select>
          <select value={filterIndustry} onChange={(e) => setFilterIndustry(e.target.value)}
            className="px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200">
            <option value="all">All Industries</option>
            {industries.map((ind) => <option key={ind} value={ind}>{ind}</option>)}
          </select>
          <span className="text-sm text-gray-500 ml-auto">{sorted.length} accounts</span>
        </div>

        <div className="mt-4 overflow-x-auto rounded-xl border border-gray-800">
          <table className="w-full text-sm">
            <thead className="bg-gray-900 text-gray-400">
              <tr>
                {[["ACCOUNT_ID","Account"],["INDUSTRY","Industry"],["TIER","Tier"],["HEALTH_SCORE","Health Score"],
                  ["RISK","Risk"],["AVG_SENTIMENT","Sentiment"],["SUPPORT_TICKET_COUNT","Tickets"],["DAYS_SINCE_LAST_ACTIVE","Days Inactive"]
                ].map(([key, label]) => (
                  <th key={key} onClick={() => handleSort(key)}
                    className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide cursor-pointer hover:text-gray-200 select-none transition-colors">
                    {label} {sortCol === key ? (sortAsc ? "↑" : "↓") : ""}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800/50">
              {sorted.map((a) => {
                const risk = getRisk(a);
                const isOpen = expanded === a.ACCOUNT_ID;
                return (
                  <>
                    <tr key={a.ACCOUNT_ID} onClick={() => setExpanded(isOpen ? null : a.ACCOUNT_ID)}
                      className={`cursor-pointer transition-colors ${isOpen ? "bg-gray-800/60" : "hover:bg-gray-900/80"}`}>
                      <td className="px-4 py-3 font-medium text-blue-400">{a.ACCOUNT_ID}</td>
                      <td className="px-4 py-3 text-gray-300">{a.INDUSTRY}</td>
                      <td className="px-4 py-3 text-gray-300 capitalize">{a.TIER}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <div className="w-16 bg-gray-800 rounded-full h-1.5">
                            <div className={`h-1.5 rounded-full ${a.HEALTH_SCORE >= 65 ? "bg-emerald-500" : a.HEALTH_SCORE >= 40 ? "bg-yellow-500" : "bg-red-500"}`}
                              style={{ width: `${Math.min(a.HEALTH_SCORE, 100)}%` }} />
                          </div>
                          <span className="font-medium text-white">{a.HEALTH_SCORE}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${tierBadge[risk]}`}>{tierLabel[risk]}</span>
                      </td>
                      <td className="px-4 py-3">
                        {a.AVG_SENTIMENT != null
                          ? <span className={a.AVG_SENTIMENT >= 0 ? "text-emerald-400" : "text-red-400"}>{a.AVG_SENTIMENT.toFixed(2)}</span>
                          : <span className="text-gray-600">—</span>}
                      </td>
                      <td className="px-4 py-3 text-gray-300">{a.SUPPORT_TICKET_COUNT ?? <span className="text-gray-600">—</span>}</td>
                      <td className="px-4 py-3 text-gray-300">{a.DAYS_SINCE_LAST_ACTIVE ?? <span className="text-gray-600">—</span>}</td>
                    </tr>
                    {isOpen && <ExpandedRow key={`${a.ACCOUNT_ID}-detail`} account={a} />}
                  </>
                );
              })}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}

export default App;