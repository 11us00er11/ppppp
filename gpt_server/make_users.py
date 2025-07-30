from werkzeug.security import generate_password_hash

minji_pw = "minji123"
jisoo_pw = "jisoo456"

print("minji:", generate_password_hash(minji_pw))
print("jisoo:", generate_password_hash(jisoo_pw))
