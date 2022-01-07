### Example node definition

```rb
node 'n0.ajr-mbp' {
  class { 'fastmc':
    id     => mc0,
    port   => 25566,
    jar    => 'https://papermc.io/api/v2/projects/paper/versions/1.18.1/builds/137/downloads/paper-1.18.1-137.jar',
    admins => ['ajr'],
  }
}
```

