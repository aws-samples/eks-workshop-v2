# EKS Worskhop - FAQ

### Q: When I run `make serve` I get an error saying `failed to extract shortcode: template for shortcode "expand" not found`

This happens when the git submodule for the hugo theme is not present. Run the following command in the root of the cloned repository:

```
git submodule update --init
```
