-- Deprecated compatibility shim.
-- Vehicle weather is owned by Vehicles/CSR_VehicleWeather.lua.
CSR_VehicleWeatherIngress = CSR_VehicleWeatherIngress or {
    deprecated = true,
}

_G.CSR_VehicleWeatherIngress = CSR_VehicleWeatherIngress
return CSR_VehicleWeatherIngress
