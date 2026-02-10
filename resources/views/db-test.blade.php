<!DOCTYPE html>
<html>
<head>
    <title>Database Test</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Database Connection Test</h1>
    <p>{{ $connected }}</p>
    
    <h2>Equipment Table</h2>
    @if($equipment->count() > 0)
        <ul>
        @foreach($equipment as $item)
            <li>ID: {{ $item->id }} - Type: {{ $item->equipment_type }} - Code: {{ $item->scada_code }}</li>
        @endforeach
        </ul>
    @else
        <p>No equipment found</p>
    @endif
    
    <a href="/">Back to main form</a>
</body>
</html>
