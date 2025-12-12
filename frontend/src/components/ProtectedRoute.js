import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const ProtectedRoute = ({ children, allowedRoles }) => {
    const { isLoggedIn, userRole } = useAuth();
    const location = useLocation();

    if (!isLoggedIn) {
        // Si no está logueado, guardar la ubicación intentada para redirigir después
        return <Navigate to="/login" state={{ from: location }} replace />;
    }

    // Si se especifican roles permitidos y el usuario no tiene uno de ellos
    if (allowedRoles && !allowedRoles.includes(userRole)) {
        // Redirigir a una página de "No Autorizado" o al Home
        // Por simplicidad, redirigimos al Home
        return <Navigate to="/" replace />;
    }

    return children;
};

export default ProtectedRoute;