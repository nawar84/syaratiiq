<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            abort(403, 'Unauthorized role.');
        }

        if ($user->isAdmin()) {
            return $next($request);
        }

        $userRole = $user->role;
        if ($userRole === 'visitor') {
            $userRole = 'buyer';
        }

        $allowed = array_map(fn ($r) => $r === 'visitor' ? 'buyer' : $r, $roles);

        if (! in_array($userRole, $allowed, true)) {
            abort(403, 'Unauthorized role.');
        }

        return $next($request);
    }
}
