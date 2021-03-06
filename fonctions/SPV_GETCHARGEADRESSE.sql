SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Fonction		: SPV_GETCHARGEADRESSE
-- Paramètre d'entrée	: @v_adr_idsysteme : Clé système adresse
--			  @v_adr_idbase : Clé base adresse
--			  @v_adr_idsousbase : Clé sous-base adresse
--			  @v_tag_idtypeagv : Type AGV
--			  @v_accesbase : Côté accès base
--			  @v_hauteur : Hauteur
--			  @v_largeur : Largeur
--			  @v_longueur : Longueur
--			  @v_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
--			  @v_directCall : Appel direct
--			    Permet de ne pas compter deux fois les emplacements accessible par
--				les deux accès
-- Paramètre de sortie	: Capacité de stockage ou stockabilité
-- Descriptif		: Récupération de la capacité de stockage d'une adresse
--			  en fonction des dimensions d'une charge ou  de la stockabilité
--			  d'une charge sur une adresse
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_GETCHARGEADRESSE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge_next int, @v_hauteur smallint, @v_largeur smallint, @v_longueur smallint,
	@v_position tinyint, @v_directCall bit)
	RETURNS smallint
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_capacite smallint,
	@v_capacitecouche smallint,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit,
	@v_bas_gerbage bit,
	@v_tag_fourche smallint,
	@v_str_couche tinyint,
	@v_str_hauteur smallint,
	@v_str_longueur_debut_courante smallint,
	@v_str_longueur_fin_initiale smallint,
	@v_str_longueur_fin_courante smallint,
	@v_str_ecart_industriel smallint,
	@v_str_ecart_exploitation smallint,
	@v_str_offsetprofondeur int,
	@v_str_offsetniveau int,
	@v_chg_idcharge_last int,
	@v_chg_largeur smallint,
	@v_profondeur smallint,
	@v_rang smallint,
	@v_par_valeur varchar(128),
	@v_gerbage bit,
	@v_offsetprofondeur int,
	@v_couche tinyint,
	@v_fin smallint,
	@v_delta_debut smallint,
	@v_delta_fin smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	SET @v_capacite = 0
	SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION, @v_bas_gerbage = BAS_GERBAGE
			FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
		IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
		BEGIN
			IF @v_longueur IS NOT NULL AND (@v_bas_gerbage = 0 OR (@v_bas_gerbage = 1 AND @v_hauteur IS NOT NULL))
				AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase)
			BEGIN
				SET @v_profondeur = CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE
					CASE ISNULL(@v_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN @v_longueur + (@v_tag_fourche - @v_longueur) / 2
					WHEN @OPTI_TABLIER THEN @v_tag_fourche ELSE @v_longueur END END
				IF @v_longueur >= @v_tag_fourche
				BEGIN
					SET @v_delta_debut = 0
					SET @v_delta_fin = 0
				END
				ELSE
				BEGIN
					SET @v_delta_debut = @v_tag_fourche - @v_profondeur
					SET @v_delta_fin = CASE ISNULL(@v_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
						WHEN @OPTI_TABLIER THEN @v_tag_fourche - @v_longueur ELSE 0 END
				END
				IF ISNULL(@v_accesbase, 0) = 0
					SELECT TOP 1 @v_offsetprofondeur = CHG_POSY, @v_couche = CHG_COUCHE  FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
						AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 ORDER BY CHG_POSY
				ELSE
					SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR, @v_couche = CHG_COUCHE FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
						WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
						AND CHG_TODESTROY = 0 ORDER BY CHG_POSY + LONGUEUR DESC
				DECLARE c_structure CURSOR LOCAL FAST_FORWARD FOR SELECT A.STR_COUCHE, A.STR_HAUTEUR_COURANTE, A.STR_LONGUEUR_DEBUT_COURANTE,
					A.STR_LONGUEUR_FIN_INITIALE, A.STR_LONGUEUR_FIN_COURANTE, A.STR_ECART_EXPLOITATION, A.STR_ECART_INDUSTRIEL
					FROM STRUCTURE A WHERE A.STR_SYSTEME = @v_adr_idsysteme AND A.STR_BASE = @v_adr_idbase AND A.STR_SOUSBASE = @v_adr_idsousbase
					AND A.STR_AUTORISATION_DEPOSE = 1 AND NOT EXISTS (SELECT 1 FROM STRUCTURE B WHERE B.STR_SYSTEME = A.STR_SYSTEME AND B.STR_BASE = A.STR_BASE AND B.STR_SOUSBASE = A.STR_SOUSBASE
					AND B.STR_COUCHE < A.STR_COUCHE AND B.STR_AUTORISATION_DEPOSE = 0)
				OPEN c_structure
				FETCH NEXT FROM c_structure INTO @v_str_couche, @v_str_hauteur, @v_str_longueur_debut_courante, @v_str_longueur_fin_initiale, @v_str_longueur_fin_courante, @v_str_ecart_industriel, @v_str_ecart_exploitation
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @v_capacitecouche = 0
					SET @v_chg_idcharge_last = NULL
					SET @v_rang = NULL
					SET @v_str_offsetniveau = NULL
					IF ISNULL(@v_accesbase, 0) = 0
					BEGIN
						IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0)
							SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_rang = CHG_RANG, @v_str_offsetprofondeur = CASE WHEN CHG_POSY > @v_str_longueur_fin_courante THEN @v_str_longueur_fin_courante ELSE CHG_POSY END
								FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
								AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0
								ORDER BY CHG_POSY, CHG_POSZ DESC
						ELSE
							SET @v_str_offsetprofondeur = @v_str_longueur_fin_courante + @v_delta_fin + ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel)
						IF @v_offsetprofondeur IS NOT NULL
						BEGIN
							IF @v_couche = @v_str_couche
								SET @v_str_offsetprofondeur = @v_offsetprofondeur
							ELSE
								SET @v_str_offsetprofondeur = CASE WHEN @v_str_offsetprofondeur - ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) - CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END > @v_offsetprofondeur THEN @v_offsetprofondeur + CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END ELSE @v_str_offsetprofondeur END
						END
						-- Retrait du @v_delta_debut car le point de navigation doit se trouver sur le tronçon
						IF @v_str_offsetprofondeur > @v_str_longueur_debut_courante
							SET @v_capacitecouche = (@v_str_offsetprofondeur - @v_str_longueur_debut_courante - CASE WHEN @v_str_longueur_debut_courante > @v_delta_debut THEN 0 ELSE @v_delta_debut - @v_str_longueur_debut_courante END) / (ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + @v_profondeur)
					END
					ELSE
					BEGIN
						IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0)
							SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_rang = CHG_RANG, @v_str_offsetprofondeur = CASE WHEN CHG_POSY + LONGUEUR < @v_str_longueur_debut_courante THEN @v_str_longueur_debut_courante ELSE CHG_POSY + LONGUEUR END
								FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
								WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
								AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0
								ORDER BY CHG_POSY DESC, CHG_POSZ DESC
						ELSE
							SET @v_str_offsetprofondeur = @v_str_longueur_debut_courante - @v_delta_fin - ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel)
						IF @v_offsetprofondeur IS NOT NULL
						BEGIN
							IF ((@v_couche = @v_str_couche AND @v_directCall = 0) OR (ISNULL(@v_accesbase, 0) = 1 AND @v_directCall = 1))
								SET @v_str_offsetprofondeur = @v_offsetprofondeur
							ELSE
								SET @v_str_offsetprofondeur = CASE WHEN @v_str_offsetprofondeur + ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END < @v_offsetprofondeur THEN @v_offsetprofondeur - CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END ELSE @v_str_offsetprofondeur END
						END
						-- Pas de retrait du @v_delta_debut car on suppose que le tronçon est suffisemment long
						IF @v_str_offsetprofondeur < @v_str_longueur_fin_courante
							SET @v_capacitecouche = (@v_str_longueur_fin_courante - @v_str_offsetprofondeur ) / (ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + @v_profondeur)
					END
					IF @v_bas_gerbage = 1
					BEGIN
						SELECT @v_str_offsetniveau = (SELECT SUM(ISNULL(CHG_HAUTEUR, ISNULL(GBR_HAUTEUR, EMB_HAUTEUR))) FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
							LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang)
						SET @v_capacitecouche = @v_capacitecouche * (@v_str_hauteur / @v_hauteur)
						IF @v_chg_idcharge_next IS NOT NULL
						BEGIN
							IF @v_chg_idcharge_last IS NOT NULL
							BEGIN
								SET @v_gerbage = 0
								-- Récupération de la fonction d'évalution des conditions de gerbage
								SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'EVALUE_GERBAGE'
								IF (@v_par_valeur IS NOT NULL)
								BEGIN
									EXEC @v_gerbage = @v_par_valeur @v_chg_idcharge_last, @v_chg_idcharge_next
									SET @v_error = @@ERROR
								END
								ELSE
									SET @v_gerbage = 1
								IF @v_status = @CODE_OK AND @v_error = 0 AND @v_gerbage = 1
									SET @v_capacitecouche = @v_capacitecouche + ((@v_str_hauteur - @v_str_offsetniveau) / @v_hauteur)
							END
						END
						ELSE
							IF @v_str_offsetniveau IS NOT NULL AND ((ISNULL(@v_accesbase, 0) = 0 AND @v_directCall = 1) OR (@v_directCall = 0))
								SET @v_capacitecouche = @v_capacitecouche + ((@v_str_hauteur - @v_str_offsetniveau) / @v_hauteur)
					END
					SET @v_capacite = @v_capacite + @v_capacitecouche
					IF @v_chg_idcharge_next IS NOT NULL AND @v_capacite >= 1
						BREAK
					FETCH NEXT FROM c_structure INTO @v_str_couche, @v_str_hauteur, @v_str_longueur_debut_courante, @v_str_longueur_fin_initiale, @v_str_longueur_fin_courante, @v_str_ecart_industriel, @v_str_ecart_exploitation
				END
				CLOSE c_structure
				DEALLOCATE c_structure
			END
		END
		ELSE IF ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
			SELECT @v_capacite = CASE WHEN NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase)
				THEN 1 ELSE 0 END
	END
	RETURN @v_capacite
END

