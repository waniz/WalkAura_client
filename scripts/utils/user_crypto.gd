class_name UserCrypto extends Node

# func generate_salt(length = 32):
	# var crypto = Crypto.new()
	# return crypto.generate_random_bytes(length).hex_encode()
	
func hash_password(password: String):
	var passwordData = password.to_utf8_buffer()
	return hash_data(passwordData)
	
func hash_data(passwordData):
	var hashContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update(passwordData)
	var hash = hashContext.finish()
	return hash.hex_encode()
