SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_STRUCTURE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_str_systeme : Système
--			  @v_str_base : Base
--			  v_str_sousbase : Sous-base
--			  @v_str_couche : Couche
--			  @v_str_cote : Cote
--			  @v_str_hauteur : Hauteur
--			  @v_str_largeur : Largeur
--			  @v_str_longueur_debut : Longueur de début
--			  @v_str_longueur_fin : Longueur de fin
--			  @v_str_ecart_industriel : Ecart industriel
--			  @v_str_ecart_exploitation : Ecart exploitation
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des structures
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_STRUCTURE]
	@v_action smallint,
	@v_str_systeme bigint,
	@v_str_base bigint,
	@v_str_sousbase bigint,
	@v_str_couche tinyint,
	@v_str_cote smallint,
	@v_str_hauteur int,
	@v_str_largeur int,
	@v_str_longueur_debut int,
	@v_str_longueur_fin int,
	@v_str_ecart_industriel smallint,
	@v_str_ecart_exploitation smallint,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error smallint,
	@v_local bit

-- Initialisation des variables
	SET @v_retour = 113
	SET @v_error = 0

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN STRUCTURE
	END
	IF @v_str_sousbase IS NULL AND @v_action IN (0, 1)
	BEGIN
		IF EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = @v_str_systeme AND BAS_BASE = @v_str_base AND BAS_RAYONNAGE = 1 AND BAS_ACCUMULATION = 0)
		BEGIN
			IF EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_str_systeme AND ADR_BASE = @v_str_base AND ADR_NIVEAU = @v_str_couche HAVING COUNT(*) > 1)
			BEGIN
				DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_SOUSBASE FROM ADRESSE WHERE ADR_SYSTEME = @v_str_systeme AND ADR_BASE = @v_str_base AND ADR_NIVEAU = @v_str_couche
				OPEN c_adresse
				FETCH NEXT FROM c_adresse INTO @v_str_sousbase
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					EXEC @v_error = CFG_STRUCTURE @v_action, @v_str_systeme, @v_str_base, @v_str_sousbase, 1, @v_str_cote, @v_str_hauteur, @v_str_largeur, @v_str_longueur_debut, @v_str_longueur_fin, @v_str_ecart_industriel, @v_str_ecart_exploitation, @v_retour out
					FETCH NEXT FROM c_adresse INTO @v_str_sousbase
				END
				CLOSE c_adresse
				DEALLOCATE c_adresse
			END
			ELSE
			BEGIN
				SELECT @v_str_sousbase = ADR_SOUSBASE FROM ADRESSE WHERE ADR_SYSTEME = @v_str_systeme AND ADR_BASE = @v_str_base AND ADR_NIVEAU = @v_str_couche
				EXEC @v_error = CFG_STRUCTURE @v_action, @v_str_systeme, @v_str_base, @v_str_sousbase, 1, @v_str_cote, @v_str_hauteur, @v_str_largeur, @v_str_longueur_debut, @v_str_longueur_fin, @v_str_ecart_industriel, @v_str_ecart_exploitation, @v_retour out
			END
		END
		ELSE
		BEGIN
			SELECT @v_str_sousbase = ADR_SOUSBASE FROM ADRESSE WHERE ADR_SYSTEME = @v_str_systeme AND ADR_BASE = @v_str_base
			EXEC @v_error = CFG_STRUCTURE @v_action, @v_str_systeme, @v_str_base, @v_str_sousbase, @v_str_couche, @v_str_cote, @v_str_hauteur, @v_str_largeur, @v_str_longueur_debut, @v_str_longueur_fin, @v_str_ecart_industriel, @v_str_ecart_exploitation, @v_retour out
		END
	END
	ELSE
	BEGIN
		IF @v_action = 0
		BEGIN
			INSERT INTO STRUCTURE (STR_SYSTEME, STR_BASE, STR_SOUSBASE, STR_COUCHE, STR_COTE, STR_LARGEUR, STR_ECART_INDUSTRIEL,
				STR_LONGUEUR_DEBUT_INITIALE, STR_LONGUEUR_DEBUT_COURANTE, STR_LONGUEUR_FIN_INITIALE, STR_LONGUEUR_FIN_COURANTE,
				STR_AUTORISATION_PRISE, STR_AUTORISATION_DEPOSE, STR_HAUTEUR_INITIALE, STR_HAUTEUR_COURANTE)
				VALUES (@v_str_systeme, @v_str_base, @v_str_sousbase, @v_str_couche, @v_str_cote, @v_str_largeur, @v_str_ecart_industriel,
				@v_str_longueur_debut, @v_str_longueur_debut, @v_str_longueur_fin, @v_str_longueur_fin, 1, 1, @v_str_hauteur, @v_str_hauteur)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_action = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_str_systeme AND STR_BASE = @v_str_base AND STR_SOUSBASE = @v_str_sousbase AND STR_COUCHE = @v_str_couche)
			BEGIN
				UPDATE STRUCTURE SET STR_COTE = @v_str_cote, STR_LARGEUR = @v_str_largeur,
					STR_HAUTEUR_INITIALE = @v_str_hauteur, STR_HAUTEUR_COURANTE = ISNULL(CASE WHEN STR_HAUTEUR_COURANTE > @v_str_hauteur THEN @v_str_hauteur ELSE CASE WHEN @v_str_hauteur IS NULL THEN @v_str_hauteur ELSE STR_HAUTEUR_COURANTE END END, @v_str_hauteur),
					STR_LONGUEUR_DEBUT_INITIALE = @v_str_longueur_debut, STR_LONGUEUR_FIN_INITIALE = @v_str_longueur_fin,
					STR_LONGUEUR_DEBUT_COURANTE = CASE WHEN STR_LONGUEUR_DEBUT_COURANTE < @v_str_longueur_debut THEN @v_str_longueur_debut ELSE STR_LONGUEUR_DEBUT_COURANTE END,
					STR_LONGUEUR_FIN_COURANTE = CASE WHEN STR_LONGUEUR_FIN_COURANTE > @v_str_longueur_fin THEN @v_str_longueur_fin ELSE STR_LONGUEUR_FIN_COURANTE END,
					STR_ECART_INDUSTRIEL = @v_str_ecart_industriel, STR_ECART_EXPLOITATION = CASE WHEN STR_ECART_EXPLOITATION < @v_str_ecart_industriel THEN @v_str_ecart_industriel ELSE STR_ECART_EXPLOITATION END
					WHERE STR_SYSTEME = @v_str_systeme AND STR_BASE = @v_str_base AND STR_SOUSBASE = @v_str_sousbase AND STR_COUCHE = @v_str_couche
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				EXEC @v_error = CFG_STRUCTURE 0, @v_str_systeme, @v_str_base, @v_str_sousbase, @v_str_couche, @v_str_cote, @v_str_hauteur, @v_str_largeur, @v_str_longueur_debut, @v_str_longueur_fin, @v_str_ecart_industriel, @v_str_ecart_exploitation, @v_retour out
		END
		ELSE IF @v_action = 2
		BEGIN
			DELETE STRUCTURE WHERE STR_SYSTEME = @v_str_systeme AND STR_BASE = @v_str_base AND STR_COUCHE >= @v_str_couche
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	IF @v_local = 1
	BEGIN
		IF ((@v_error = 0) AND (@v_retour = 0))
			COMMIT TRAN STRUCTURE
		ELSE
			ROLLBACK TRAN STRUCTURE
	END
	RETURN @v_error

