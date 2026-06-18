<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\SellerAccountService;
use Illuminate\Http\Request;

class AdminSellerAccountController extends Controller
{
    public function __construct(private readonly SellerAccountService $sellerAccounts)
    {
    }

    public function index(Request $request)
    {
        $query = User::query()
            ->where('role', 'owner')
            ->with(['province', 'exhibitions'])
            ->latest();

        if ($request->filled('status')) {
            $query->where('account_status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = (string) $request->query('search');
            $query->where(function ($q) use ($search): void {
                $q->where('showroom_name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $paginated = $query->paginate((int) $request->query('per_page', 30));

        $paginated->getCollection()->transform(
            fn (User $user) => $this->sellerAccounts->formatSellerAccount($user)
        );

        return response()->json($paginated);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'showroom_name' => ['required', 'string', 'max:255'],
            'owner_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:25', 'unique:users,phone'],
            'province_id' => ['required', 'exists:provinces,id'],
            'subscription_type' => ['required', 'in:free_trial,monthly,premium'],
            'subscription_end' => ['required', 'date', 'after_or_equal:today'],
        ]);

        $result = $this->sellerAccounts->create($data);

        return response()->json([
            'message' => 'Seller account created.',
            'user' => $this->sellerAccounts->formatSellerAccount($result['user']),
            'username' => $result['user']->username,
            'password' => $result['password'],
        ], 201);
    }

    public function show(int $id)
    {
        $user = User::where('role', 'owner')->with(['province', 'exhibitions'])->findOrFail($id);

        return response()->json($this->sellerAccounts->formatSellerAccount($user));
    }

    public function update(Request $request, int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);

        $data = $request->validate([
            'showroom_name' => ['sometimes', 'required', 'string', 'max:255'],
            'owner_name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'required', 'string', 'max:25', 'unique:users,phone,'.$id],
            'province_id' => ['sometimes', 'required', 'exists:provinces,id'],
            'subscription_type' => ['sometimes', 'required', 'in:free_trial,monthly,premium'],
            'subscription_end' => ['sometimes', 'required', 'date'],
        ]);

        $updated = $this->sellerAccounts->update($user, $data);

        return response()->json($this->sellerAccounts->formatSellerAccount($updated));
    }

    public function resetPassword(int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);
        $result = $this->sellerAccounts->resetPassword($user);

        return response()->json([
            'message' => 'Password reset.',
            'user' => $this->sellerAccounts->formatSellerAccount($result['user']),
            'username' => $result['user']->username,
            'password' => $result['password'],
        ]);
    }

    public function renewSubscription(Request $request, int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);

        $data = $request->validate([
            'subscription_end' => ['required', 'date', 'after_or_equal:today'],
            'subscription_type' => ['nullable', 'in:free_trial,monthly,premium'],
        ]);

        $result = $this->sellerAccounts->renewSubscription(
            $user,
            \Carbon\Carbon::parse($data['subscription_end']),
            $data['subscription_type'] ?? null,
        );

        return response()->json([
            'message' => 'Subscription renewed.',
            'user' => $this->sellerAccounts->formatSellerAccount($result['user']),
        ]);
    }

    public function suspend(int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);
        $updated = $this->sellerAccounts->suspend($user);

        return response()->json($this->sellerAccounts->formatSellerAccount($updated));
    }

    public function activate(int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);
        $updated = $this->sellerAccounts->activate($user);

        return response()->json($this->sellerAccounts->formatSellerAccount($updated));
    }

    public function destroy(int $id)
    {
        $user = User::where('role', 'owner')->findOrFail($id);
        $this->sellerAccounts->delete($user);

        return response()->json(['message' => 'Seller account deleted.']);
    }
}
