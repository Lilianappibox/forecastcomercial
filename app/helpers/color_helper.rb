module ColorHelper
  KAM_PALETTE = [
    { bg: "bg-blue-50", border: "border-blue-400", dot: "bg-blue-500", text: "text-blue-700" },
    { bg: "bg-emerald-50", border: "border-emerald-400", dot: "bg-emerald-500", text: "text-emerald-700" },
    { bg: "bg-violet-50", border: "border-violet-400", dot: "bg-violet-500", text: "text-violet-700" },
    { bg: "bg-amber-50", border: "border-amber-400", dot: "bg-amber-500", text: "text-amber-700" },
    { bg: "bg-pink-50", border: "border-pink-400", dot: "bg-pink-500", text: "text-pink-700" },
    { bg: "bg-cyan-50", border: "border-cyan-400", dot: "bg-cyan-500", text: "text-cyan-700" },
    { bg: "bg-rose-50", border: "border-rose-400", dot: "bg-rose-500", text: "text-rose-700" },
    { bg: "bg-indigo-50", border: "border-indigo-400", dot: "bg-indigo-500", text: "text-indigo-700" }
  ].freeze

  def kam_color(user)
    KAM_PALETTE[user.id % KAM_PALETTE.length]
  end
end
