<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Car;
use App\Models\Exhibition;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminManagementController extends Controller
{
    public function users()
    {
        return response()->json(User::latest()->paginate(30));
    }

    public function updateUserRole(Request $request, int $id)
    {
        $data = $request->validate([
            'role' => ['required', 'in:admin,owner,buyer'],
        ]);

        $user = User::findOrFail($id);
        $actor = $request->user();

        if ($user->id === $actor->id) {
            abort(422, 'Cannot change your own role.');
        }

        if ($user->isAdmin() && $data['role'] !== 'admin') {
            $adminCount = User::where('role', 'admin')->count();
            if ($adminCount <= 1) {
                abort(422, 'Cannot remove the last admin.');
            }
        }

        $user->update(['role' => $data['role']]);

        return response()->json($user);
    }

    public function showrooms()
    {
        return response()->json(
            Exhibition::with(['province', 'user', 'subscriptions'])->latest()->paginate(30)
        );
    }

    public function cars()
    {
        return response()->json(
            Car::with(['brand', 'exhibition.province'])->latest()->paginate(30)
        );
    }

    public function subscriptions()
    {
        return response()->json(
            Subscription::with(['user', 'exhibition'])->latest()->paginate(30)
        );
    }

    public function revenue()
    {
        $monthExpression = match (DB::connection()->getDriverName()) {
            'sqlite' => "strftime('%Y-%m', renewed_at)",
            'pgsql' => "to_char(renewed_at, 'YYYY-MM')",
            default => "DATE_FORMAT(renewed_at, '%Y-%m')",
        };

        $monthly = Subscription::query()
            ->selectRaw("$monthExpression as month, SUM(amount) as revenue, COUNT(*) as renewals")
            ->whereNotNull('renewed_at')
            ->groupBy('month')
            ->orderByDesc('month')
            ->limit(12)
            ->get();

        return response()->json([
            'total_revenue' => Subscription::sum('amount'),
            'active_subscriptions' => Subscription::whereIn('status', ['trial', 'active'])
                ->where('ends_at', '>', now())
                ->count(),
            'monthly_reports' => $monthly,
        ]);
    }
}
