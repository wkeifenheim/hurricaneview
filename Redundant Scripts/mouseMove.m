function mouseMove(object, eventdata)
    C = get(gca, 'CurrentPoint');
    %title(gca, ['(X.Y) = (', num2str(C(1,1)), ', ',num2str(C(1,2)), ')']);
    [lat lon] = intrinsicToGeographic(gca, C(1,1), C(1,2));
    title(gca, ['(lat, lon) = (', num2str(lat), ', ',num2str(lon), ')']);
    
end