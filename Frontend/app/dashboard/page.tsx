"use client"

import { useEffect, useMemo, useState } from "react"
import { AlertTriangle, ArrowRight, CheckCircle2, Clock, Loader2, Mail, Package, User } from "lucide-react"
import Link from "next/link"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/contexts/AuthContext"
import { productApi, type Product } from "@/lib/api"

const demoProducts: Product[] = [
  {
    id: 1,
    name: "Organic Milk 1L",
    sku: "PRD-001",
    barcode: "890100000001",
    category: "Dairy",
    image_url: null,
    created_at: "2026-06-24T09:00:00Z",
    updated_at: "2026-06-24T09:00:00Z",
  },
  {
    id: 2,
    name: "Greek Yogurt 500g",
    sku: "PRD-045",
    barcode: "890100000045",
    category: "Dairy",
    image_url: null,
    created_at: "2026-06-26T09:00:00Z",
    updated_at: "2026-06-26T09:00:00Z",
  },
  {
    id: 3,
    name: "Whole Wheat Bread",
    sku: "PRD-089",
    barcode: "890100000089",
    category: "Bakery",
    image_url: null,
    created_at: "2026-06-29T09:00:00Z",
    updated_at: "2026-06-29T09:00:00Z",
  },
  {
    id: 4,
    name: "Fresh Orange Juice 1L",
    sku: "PRD-123",
    barcode: "890100000123",
    category: "Beverages",
    image_url: null,
    created_at: "2026-07-01T09:00:00Z",
    updated_at: "2026-07-01T09:00:00Z",
  },
]

const expiringItems = [
  { id: 1, name: "Organic Milk 1L", sku: "PRD-001", expiryDate: "2026-07-06", daysLeft: 4 },
  { id: 2, name: "Greek Yogurt 500g", sku: "PRD-045", expiryDate: "2026-07-09", daysLeft: 7 },
  { id: 3, name: "Whole Wheat Bread", sku: "PRD-089", expiryDate: "2026-07-11", daysLeft: 9 },
  { id: 4, name: "Fresh Orange Juice 1L", sku: "PRD-123", expiryDate: "2026-07-15", daysLeft: 13 },
]

export default function DashboardHome() {
  const { user } = useAuth()
  const [products, setProducts] = useState<Product[]>(demoProducts)
  const [isLoading, setIsLoading] = useState(true)
  const [apiMessage, setApiMessage] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true

    const loadProducts = async () => {
      if (!process.env.NEXT_PUBLIC_API_URL) {
        setProducts(demoProducts)
        setApiMessage("Backend API URL is not configured, showing starter data.")
        setIsLoading(false)
        return
      }

      try {
        const apiProducts = await productApi.getAll()
        if (isMounted) {
          setProducts(apiProducts.length > 0 ? apiProducts : demoProducts)
          setApiMessage(apiProducts.length > 0 ? null : "No backend products yet, showing starter data.")
        }
      } catch {
        if (isMounted) {
          setProducts(demoProducts)
          setApiMessage("Backend is not reachable, showing starter data.")
        }
      } finally {
        if (isMounted) {
          setIsLoading(false)
        }
      }
    }

    loadProducts()

    return () => {
      isMounted = false
    }
  }, [])

  const stats = useMemo(
    () => [
      { label: "Total Products", value: products.length, icon: Package, tone: "text-blue-600 bg-blue-50" },
      { label: "Expiring Soon", value: expiringItems.length, icon: AlertTriangle, tone: "text-amber-600 bg-amber-50" },
      { label: "Validated Today", value: 24, icon: CheckCircle2, tone: "text-green-600 bg-green-50" },
      { label: "Needs Review", value: 3, icon: Clock, tone: "text-red-600 bg-red-50" },
    ],
    [products.length],
  )

  return (
    <div className="p-8 space-y-8">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex items-center gap-4">
          <div className="size-16 rounded-full bg-gray-100 flex items-center justify-center">
            <User className="size-8 text-gray-500" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{user?.name || "Inventory Manager"}</h1>
            <div className="flex items-center gap-2 text-gray-500">
              <Mail className="size-4" />
              <span>{user?.email || "manager@example.com"}</span>
            </div>
          </div>
        </div>
        <Button asChild className="gap-2 self-start lg:self-auto">
          <Link href="/dashboard/inventory">
            Open Inventory
            <ArrowRight className="size-4" />
          </Link>
        </Button>
      </div>

      {apiMessage && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {apiMessage}
        </div>
      )}

      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.label}>
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-gray-500">{stat.label}</CardTitle>
                <div className={`rounded-lg p-2 ${stat.tone}`}>
                  <stat.icon className="size-5" />
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-gray-900">{stat.value}</div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-xl font-bold text-gray-900">Early Expiring Items</CardTitle>
          {isLoading && <Loader2 className="size-5 animate-spin text-gray-400" />}
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Product Name</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">SKU</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Expiry Date</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">Days Left</th>
                </tr>
              </thead>
              <tbody>
                {expiringItems.map((item) => (
                  <tr key={item.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                    <td className="py-4 px-4 font-medium text-gray-900">{item.name}</td>
                    <td className="py-4 px-4 text-gray-600 font-mono">{item.sku}</td>
                    <td className="py-4 px-4 text-gray-600">{item.expiryDate}</td>
                    <td className="py-4 px-4">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          item.daysLeft <= 7 ? "bg-red-100 text-red-800" : "bg-orange-100 text-orange-800"
                        }`}
                      >
                        <AlertTriangle className="size-3 mr-1" />
                        {item.daysLeft} days
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
