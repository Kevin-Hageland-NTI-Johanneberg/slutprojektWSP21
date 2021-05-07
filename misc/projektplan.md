# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra).

Jag ska skapa en "Investeringssida" där man som företag kan köpa upp idéer från användare. Det fungerar på så sätt att man skapar ett konto som användare och namnet på sitt företag och får möjligheten att kryssa i en box som ger en möjlighet att själv investera i idéer. Ifall man kryssar i denna boxen måste man dessutom fylla i företagets kapital. När detta är gjort så kan man överblicka andra företags inlägg (med ideéer och uppfinningar). Ifall man är inresserad av att investera kan man gå in på inlägget för att hitta mer information och billagor. Varje inlägg har dessutom ett "offer", exempelvis "investera £1000 för 20% i företaget". Om man vill själv lägga ett annorlunda förslag kan man det också via en knapp. TL;DR Draknästet fast digitalt. 

## 2. Vyer (visa bildskisser på dina sidor).

![Grafiskt](grafiskt.png)

## 3. Databas med ER-diagram (Bild på ER-diagram).

![ER-Diagram](er-diagram.png)

## 4. Arkitektur (Beskriv filer och mappar - vad gör/innehåller de?).

Generell struktur:

db <!-- databas map -->
    databas-fil.db
misc
    bilder
    projectplan
    övriga filer
public
    css
    java-scripts
    (html)
views
    slimfiler-för-alla-sidor
app.rb
model.rb

-------

Skriva förklaring