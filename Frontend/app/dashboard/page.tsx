"use client";

import { User, Mail, Package, AlertTriangle, ArrowRight } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Mock data
const mockUser = {
  name: "John Doe",
  email: "john.doe@example.com",
  avatar: null,
};

const mockStats = {
  totalProducts: 142,
  earlyExpiring: 23,
  totalInventory: 856,
  recentValidations: 12,
};

const earlyExpiringItems = [
  {
    id: 1,
    name: "Organic Milk 1L",
    pid: "PRD-001",
    expiryDate: "2024-06-30",
    daysLeft: 6,
  },
  {
    id: 2,
    name: "Greek Yogurt 500g",
    pid: "PRD-045",
    expiryDate: "2024-07-02",
    daysLeft: 8,
  },
  {
    id: 3,
    name: "Whole Wheat Bread",
    pid: "PRD-089",
    expiryDate: "2024-07-03",
    daysLeft: 9,
  },
  {
    id: 4,
    name: "Fresh Orange Juice 1L",
    pid: "PRD-123",
    expiryDate: "2024-07-05",
    daysLeft: 11,
  },
  {
    id: 5,
    name: "Cheddar Cheese Block",
    pid: "PRD-056",
    expiryDate: "2024-07-08",
    daysLeft: 14,
  },
];

export default function DashboardHome() {
  return (
    <div className="p-8 space-y-8">
      {/* User Info */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="size-16 rounded-full bg-gray-100 flex items-center justify-center">
            <User className="size-8 text-gray-500" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{mockUser.name}</h1>
            <div className="flex items-center gap-2 text-gray-500">
              <Mail className="size-4" />
              <span>{mockUser.email}</span>
            </div>
          </div>
        </div>
        <div className="text-right text-sm text-gray-500">
          <div>Last Login: Today, 09:45 AM</div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Total Products
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-gray-900">
              {mockStats.totalProducts}
            </div>
          </CardContent>
        </Card>
        <Card className="border-orange-200 bg-orange-50">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-orange-700">
              Early Expiring Items
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-orange-600">
              {mockStats.earlyExpiring}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Total Inventory
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-gray-900">
              {mockStats.totalInventory}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Recent Validations
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-gray-900">
              {mockStats.recentValidations}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Early Expiring Items */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-xl font-bold text-gray-900">
            Early Expiring Items
          </CardTitle>
          <Button variant="secondary" className="gap-2">
            View All
            <ArrowRight className="size-4" />
          </Button>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Product Name
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    PID
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Expiry Date
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Days Left
                  </th>
                </tr>
              </thead>
              <tbody>
                {earlyExpiringItems.map((item) => (
                  <tr
                    key={item.id}
                    className="border-b border-gray-100 hover:bg-gray-50 transition-colors"
                  >
                    <td className="py-4 px-4 font-medium text-gray-900">
                      {item.name}
                    </td>
                    <td className="py-4 px-4 text-gray-600">{item.pid}</td>
                    <td className="py-4 px-4 text-gray-600">
                      {item.expiryDate}
                    </td>
                    <td className="py-4 px-4">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          item.daysLeft <= 7
                            ? "bg-red-100 text-red-800"
                            : "bg-orange-100 text-orange-800"
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
  );
}
