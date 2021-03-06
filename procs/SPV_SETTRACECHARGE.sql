SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procedure		: SPV_SETTRACECHARGE
-- Paramètre d'entrée	: @v_trc_idcharge : Identifiant charge
--			  @v_trc_typetrc : Type trace
--			  @v_trc_adrsys : Clé système adresse
--			  @v_trc_adrbase : Clé base adresse
--			  @v_trc_adrssbase : Clé sous-base adresse
--			  @v_trc_idclient : Code
--			  @v_trc_orientation : Orientation
--			  @v_trc_posx : Position en colonne
--			  @v_trc_posy : Position en profondeur
--			  @v_trc_posz : Position en niveau
--			  @v_trc_poids : Poids
--			  @v_trc_hauteur : Hauteur
--			  @v_trc_largeur : Largeur
--			  @v_trc_longueur : Longueur
--			  @v_trc_produit : Produit
--			  @v_trc_gabarit : Gabarit
--			  @v_trc_emballage : Emballage
--			  @v_trc_couche : Couche
--			  @v_trc_rang : Rang
--			  @v_trc_face : Face
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_PARAM : Paramètre incorrect
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Ajout d'une trace charge
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 
-- Auteur		: 
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------
-- Date			: 11/09/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Fractionnement de la colonne TRC_DATA
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETTRACECHARGE]
	@v_trc_idcharge int,
	@v_trc_typetrc int,
	@v_trc_adrsys bigint,
	@v_trc_adrbase bigint,
	@v_trc_adrssbase bigint,
	@v_trc_idclient varchar(20),
	@v_trc_orientation smallint,
	@v_trc_posx int,
	@v_trc_posy int,
	@v_trc_posz int,
	@v_trc_poids smallint,
	@v_trc_hauteur smallint,
	@v_trc_largeur smallint,
	@v_trc_longueur smallint,
	@v_trc_produit varchar(20),
	@v_trc_gabarit tinyint,
	@v_trc_emballage tinyint,
	@v_trc_couche tinyint,
	@v_trc_rang smallint,
	@v_trc_face bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de types de traces
DECLARE
	@TYPE_CREATION int,
	@TYPE_FIN int,
	@TYPE_DESTRUCTION int,
	@TYPE_MODIFICATION_CARACTERISTIQUE int,
	@TYPE_PRISE_CHARGE int,
	@TYPE_DEPOSE_CHARGE int

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_PARAM = 8
	SELECT @CODE_KO_SQL = 13
	SELECT @TYPE_CREATION = 1
	SELECT @TYPE_FIN = 6
	SELECT @TYPE_DESTRUCTION = 8
	SELECT @TYPE_MODIFICATION_CARACTERISTIQUE = 10
	SELECT @TYPE_PRISE_CHARGE = 11
	SELECT @TYPE_DEPOSE_CHARGE = 12

-- Initialisation des variables
	SELECT @v_error = 0
	SELECT @v_status = @CODE_KO
	SELECT @v_retour = @CODE_KO

	-- Contrôle des types de traces
	IF @v_trc_typetrc NOT IN (@TYPE_CREATION, @TYPE_FIN, @TYPE_DESTRUCTION,
			@TYPE_MODIFICATION_CARACTERISTIQUE, @TYPE_PRISE_CHARGE, @TYPE_DEPOSE_CHARGE)
		SELECT @v_retour = @CODE_KO_PARAM
	ELSE
	BEGIN
		INSERT INTO TRACE_CHARGE (TRC_DATE, TRC_IDCHARGE, TRC_TYPETRC, TRC_ADRSYS, 
			TRC_ADRBASE, TRC_ADRSSBASE, TRC_IDCLIENT, TRC_ORIENTATION, TRC_POSX, TRC_POSY, TRC_POSZ,
			TRC_POIDS, TRC_HAUTEUR, TRC_LARGEUR, TRC_LONGUEUR, TRC_PRODUIT, TRC_GABARIT,
			TRC_EMBALLAGE, TRC_COUCHE, TRC_RANG, TRC_FACE)
			VALUES (GETDATE(), @v_trc_idcharge, @v_trc_typetrc, @v_trc_adrsys, @v_trc_adrbase, @v_trc_adrssbase,
			@v_trc_idclient, @v_trc_orientation, @v_trc_posx, @v_trc_posy, @v_trc_posz, @v_trc_poids,
			@v_trc_hauteur, @v_trc_largeur, @v_trc_longueur, @v_trc_produit, @v_trc_gabarit,
			@v_trc_emballage, @v_trc_couche, @v_trc_rang, @v_trc_face)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @CODE_KO_SQL
	END
	RETURN @v_retour


