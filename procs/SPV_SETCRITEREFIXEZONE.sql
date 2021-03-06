SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_SETCRITEREFIXEMISSION
-- Paramètre d'entrée	: @v_idCritere : Identifiant du critère à initialiser
--			  @v_idZone : Identifiant de la zone concernée
--			  @v_valueCritere : valeur d'initialisation (facultatif)
-- Paramètre de sortie	: Code de retour par défaut
--			  @CODE_OK : la valorisation s'est exécutée correctement
--			  @CODE_KO_CRITERE_ZONE : Une erreur s'est produite
-- Descriptif		: Cette procédure valorise les critères fixes d'une zone
--			  - soit à partir de la valeur passée en paramètre
--			  - soit suite à un calcul
-----------------------------------------------------------------------------------------
-- Révisions									
-----------------------------------------------------------------------------------------
-- Date			: 21/02/2005									
-- Auteur		: S.Loiseau									
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 06/10/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Paramétrabilité du nom des procédures stockées standards
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETCRITEREFIXEZONE]
	@v_idCritere integer,
	@v_idZone integer,
	@v_valueCritere varchar(8000)
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
	@v_status int

-- déclaration des variables
declare @v_codeRetour integer
declare @v_calculCriZne varchar(128)

-- déclaration des constantes code retour
declare @CODE_OK tinyint
declare @CODE_KO tinyint
declare @CODE_KO_CRITERE_ZONE integer

--définition des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_CRITERE_ZONE = 33


-- intialisation de la variable code de retour 
set @v_codeRetour = @CODE_KO


-- VALORISATION DES CRITERES SYSTEMES

-- VALORISATION DES CRITERES SPECIFIQUES
	-- Recupération du nom de la fonction spécifique
	select @v_calculCriZne = case PAR_VAL when '' THEN NULL else PAR_VAL end from PARAMETRE where PAR_NOM = 'CALCUL_CRI_ZNE'
    if @v_calculCriZne is not NULL
    begin
		exec @v_status = @v_calculCriZne @v_idCritere, @v_idZone, @v_valueCritere out
		SELECT @v_error = @@ERROR
		IF NOT (@v_status = @CODE_OK AND @v_error = 0)
		SELECT @v_codeRetour = @CODE_KO_CRITERE_ZONE
	end

	if @v_codeRetour <> @CODE_KO_CRITERE_ZONE
	begin
		EXEC @v_status = INT_SETCRITEREZONE @v_idCritere, @v_idZone, CRZ_Value
		SELECT @v_error = @@ERROR
		IF @v_status = @CODE_OK AND @v_error = 0
			SELECT @v_codeRetour = @CODE_OK
		ELSE
			SELECT @v_codeRetour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	end
	return @v_codeRetour


