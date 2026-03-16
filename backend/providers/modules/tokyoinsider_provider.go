package modules

func NewTokyoInsiderProvider() *GenericProvider {
	return NewGenericProvider("TokyoInsider", "https://tokyoinsider.com")
}
